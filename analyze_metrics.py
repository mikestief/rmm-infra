import subprocess
import json
import datetime
import time
import urllib.parse

def get_access_token():
    try:
        # Use simple gcloud auth print-access-token
        result = subprocess.run(["gcloud", "auth", "print-access-token"], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error getting access token: {e}")
        return None

def fetch_timeseries(project_id, service_name, metric_type, aligner, access_token):
    # Calculate time range
    now = datetime.datetime.utcnow()
    end_time = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    start_time = (now - datetime.timedelta(hours=1)).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Construct filter
    # metric.type="run.googleapis.com/container/cpu/utilizations" AND resource.labels.service_name="SERVICE_NAME"
    filter_str = f'metric.type="{metric_type}" AND resource.labels.service_name="{service_name}"'
    encoded_filter = urllib.parse.quote(filter_str)

    url = (
        f"https://monitoring.googleapis.com/v3/projects/{project_id}/timeSeries?"
        f"filter={encoded_filter}&"
        f"interval.startTime={start_time}&"
        f"interval.endTime={end_time}&"
        f"aggregation.alignmentPeriod=300s&"
        f"aggregation.perSeriesAligner={aligner}&"
        f"aggregation.crossSeriesReducer=REDUCE_NONE" # We want individual container metrics if possible
    )

    cmd = [
        "curl", "-s", "-X", "GET",
        "-H", f"Authorization: Bearer {access_token}",
        url
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching {metric_type}: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON response for {metric_type}: {e}")
        return None

def process_data(data, metric_name):
    if not data or 'timeSeries' not in data:
        print(f"  {metric_name}: No data")
        return

    for series in data['timeSeries']:
        # Extract labels to identify container
        resource_labels = series.get('resource', {}).get('labels', {})
        metric_labels = series.get('metric', {}).get('labels', {})
        
        # Cloud Run metrics often don't label container_name directly in 'resource' for service level metrics
        # But 'container/cpu/utilizations' suggests per-container?
        # Let's check if 'container_name' is in metric labels.
        container_name = metric_labels.get('container_name', 'unknown')
        if container_name == 'unknown':
             container_name = resource_labels.get('configuration_name', 'unknown-config')


        points = series.get('points', [])
        values = []
        for p in points:
            # Distribution values when aligned with PERCENTILE return doubleValue
            if 'value' in p and 'doubleValue' in p['value']:
                values.append(p['value']['doubleValue'])
        
        if values:
            avg_val = sum(values) / len(values)
            max_val = max(values)
            print(f"  Container: {container_name}")
            print(f"    {metric_name} (P99) - Max: {max_val:.4f}, Avg: {avg_val:.4f} (Count: {len(values)})")

def main():
    project_id = "rustymaintenance"
    access_token = get_access_token()
    if not access_token:
        print("Failed to get access token.")
        return

    services = ["rmm-places-api-service", "rmm-vehicle-api-service", "rmm-ui-service"]
    metrics = {
        "CPU": "run.googleapis.com/container/cpu/utilizations",
        "Memory": "run.googleapis.com/container/memory/utilizations"
    }

    print(f"--- Analyzing Metrics for Project: {project_id} (Last 1 hour) ---")

    for service in services:
        print(f"\nService: {service}")
        for label, metric_type in metrics.items():
            # Align with P99 to see peak usage
            data = fetch_timeseries(project_id, service, metric_type, "ALIGN_PERCENTILE_99", access_token)
            process_data(data, label)

if __name__ == "__main__":
    main()
