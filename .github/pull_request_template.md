## Summary

<!-- What changed and why, in a few sentences. -->

## Linked issues

<!-- Closes #123. For cross-repo work, link the sibling PR, e.g. mikestief/rmm-vechicle-api#45. -->

- Closes #

## Checklist

- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` passes
- [ ] `terraform plan` output pasted below (factory workers: via the `factory-planner` service account)
- [ ] No resources destroyed or replaced unexpectedly
- [ ] `terraform apply` will be run by the maintainer after merge — never by an agent

## Plan output

<details><summary>terraform plan</summary>

```
<!-- paste plan here -->
```

</details>

## Risk

<!-- Required when the issue or PR is labeled `high-risk` (auth/JWT/OAuth, StoreKit/billing, SQL migrations,
rmm-infra, account deletion, BFF proxy/security headers, file uploads/GCS). Otherwise write "None". -->

- What could break:
- Blast radius:
- Rollback plan:

## Factory

<!-- Factory worker PRs only; delete this section for human-authored PRs. -->

- [ ] Labeled `factory`
- [ ] Opened as draft if blocked or `high-risk`, with open questions listed above
- [ ] No changes to `.github/workflows/**`
- [ ] Proposed a CLAUDE.md / rules edit if review feedback revealed a missing rule

