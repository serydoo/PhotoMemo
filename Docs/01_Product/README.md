# 01 Product

Product vision, positioning, MVP scope, roadmap, backlog, and UX principles belong here.

Product feedback iterations also belong here when they are driven by real usage
and are intentionally separate from architecture RFC work.

Working distinction:

- Product Line improves usability through scenario-driven feedback iterations
- Engineering Line evolves architecture through evidence-driven RFC work

Dual Loop Development:

- Product Loop:
  - `Observation -> Scenario -> Iteration -> Validation`
- Engineering Loop:
  - `Fact -> Decision -> RFC -> Verification`

Both loops may converge on the same implementation layer, but they should not
mix their source-of-truth logic.

Existing flat `Docs/` files should be migrated here in a later documentation refactor slice after `Docs/MASTER_PLAN.md` and `RepositoryAudit.md` are stable.
