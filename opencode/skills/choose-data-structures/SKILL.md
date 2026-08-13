---
name: choose-data-structures
description: Review and choose data structures from actual operations, scale, relationships, invariants, ownership, and storage constraints. Use when designing or changing core state, collection types, indexes, caches, queues, entity relationships, memory layout, or persistence models; when code complexity may be compensating for a poor representation; or when performance depends on access patterns.
---

# Choose data structures

Design the data before writing machinery around it. Prefer the simplest
representation that makes common operations, ownership, and invariants obvious.
Treat every container choice as contextual, including arrays of structs.

## Workflow

1. Inspect the existing model. Read the types, schemas, callers, mutations,
   queries, tests, and serialization boundaries. Preserve public and persistent
   contracts unless the requested change includes a migration.
2. Describe the workload before choosing a representation:
   - Expected count, maximum count, growth, and input bounds.
   - Common operations and their frequency, including lookup keys, traversal,
     ordering, insertion, deletion, and partial updates.
   - Relationships and cardinality between records.
   - Ownership, lifetime, mutation, concurrency, and sharing.
   - Persistence, serialization, compatibility, and migration requirements.
3. State the invariants. Include uniqueness, ordering, referential integrity,
   valid state transitions, and any values that must agree. Name one source of
   truth. Give every secondary index or cache an update, invalidation, or rebuild
   rule.
4. Compare the simplest plausible representation with at least one credible
   alternative. Compare correctness, implementation complexity, dominant
   operation costs, memory and locality, mutation, concurrency, serialization,
   and migration cost. Reject alternatives using requirements, not fashion.
5. Choose the least complicated representation that satisfies known bounds and
   operations. Keep callers behind focused operations when exposing the physical
   layout would make later changes expensive.
6. Verify the choice. Test invariants, boundaries, empty and maximum states,
   mutations, and index consistency. Load the `benchmark` skill before making a
   performance claim. Revisit the model when simple behavior requires repeated
   conversions, synchronized collections, or defensive repair code.

For a new core representation, record four short points in working notes before
implementation: dominant operations and scale, the selected representation, the
best rejected alternative, and the invariants plus verification plan.

## Simple starting point

Start with an array, slice, or list of cohesive structs when:

- The collection is bounded or modest.
- Iteration, filtering, batching, or serialization is common.
- Records share ownership and lifetime.
- No keyed lookup, sparse update, or relationship traversal dominates.

Keeping related fields together, even in a fairly large struct, often reduces
bookkeeping and preserves one source of truth. Split the representation when
fields have different lifetimes or access frequency, large cold values dominate
memory traffic, ownership differs, or measurements show copying and locality are
a problem.

Add structure only for a real access pattern:

- Add a map, set, or secondary index for repeated keyed membership or lookup.
- Add a queue, deque, heap, or ordered tree when its ordering and update behavior
  matches the required operations.
- Use stable identifiers when references must survive reordering, relocation, or
  persistence. Do not let incidental array positions become durable identity.
- Model graph or many-to-many relationships explicitly when traversal and
  independent updates require them.
- Treat persistent schemas as harder to change than in-memory layouts. Load the
  matching database skill before changing a database model or index.

## Warning signs

Question the representation when:

- Several mutable collections must change in lockstep.
- Common operations repeatedly scan, convert, regroup, or rebuild the data.
- Invalid combinations require defensive checks throughout the code.
- Ownership, lifetime, or the source of truth cannot be stated plainly.
- A small behavior change touches many adapters or synchronization paths.
- Callers depend on container details instead of domain operations.

Fix the representation when evidence supports it. Do not use these signs as an
excuse to redesign stable, unrelated code.

## Guardrails

- Do not treat arrays of large structs, hash maps, normalized tables, object
  graphs, or entity-component layouts as universal defaults.
- Do not add an index, cache, denormalized copy, or reverse mapping without
  naming the operation that pays for its synchronization cost.
- Do not keep two mutable sources of truth.
- Do not hide unbounded scans, growth, fan-out, or allocation behind a tidy API.
- Do not claim a representation is optimal without workload constraints and,
  where performance matters, representative measurements.
- Use the relevant language skill for ownership and container semantics. Use the
  matching database skill for persistence and the `benchmark` skill for measured
  comparisons.
