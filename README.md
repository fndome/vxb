# vxb (V eXtensible Builder)

> Minimal V implementation of the xb query builder philosophy — chainable, auto-filtered, and ready for analytics.

## ✨ Highlights

- Chain-style query builder written in V.
- Auto-filtering for nil/zero/empty inputs to avoid noisy SQL.
- Support for basic predicates (`eq`, `ne`, `gt`, `gte`, `lt`, `lte`, `like`, `like_left`, `in`).
- Sorting, limit & offset helpers.
- Generates SQL with `?` placeholders plus an ordered argument list.

## 🚀 Quick Start

```v
import vxb

fn main() {
    mut builder := vxb.of('users')
    builder.select('id', 'name', 'email')
    builder.eq('status', 'active')
    builder.gt('age', 18)
    builder.like('name', 'jo')
    builder.sort('created_at', 'desc')
    builder.limit(50)

    built := builder.build()
    sql_text, args := built.sql_of_select()
	vs_strings := args.map(vxb.scalar_to_string(it))
    println(sql_text)
    println(vs_strings)
}
```

Output:

```
SELECT id, name, email FROM users WHERE status = ? AND age > ? AND name LIKE ? ORDER BY created_at DESC LIMIT 50
['active', 18, '%jo%']
```

## 🛠️ API Surface

| Method | Description |
|--------|-------------|
| `of(table string)` | Create a new builder |
| `select(fields ...string)` | Override returned columns (defaults to `*`) |
| `eq/ne/gt/gte/lt/lte` | Add comparison predicates (auto-filter blank values) |
| `like/like_left` | Add LIKE conditions (`%value%` / `value%`) |
| `in(values []T)` | Add `IN` clause (skips empty slices) |
| `sort(field, direction)` | Append sorting (`ASC` / `DESC`) |
| `limit(value)` / `offset(value)` | Pagination helpers |
| `build()` | Produce `SqlResult { sql, args }` |

## 📦 Project Layout

```
vxb/
├── README.md
├── CHANGELOG.md
├── COMMIT_v0.0.1.txt
└── src/
    └── builder.v
```

## 📄 License

MIT License (see `LICENSE`). README kept intentionally concise—iterate freely!

