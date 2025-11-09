module vxb

struct SortSpec {
	field     string
	direction string
}

// SqlResult contains the final SQL string plus ordered arguments.
// `build()` returns this struct so the caller can prepare statements easily.
pub struct SqlResult {
	pub:
		sql  string
		args []any
}

// Builder is the chain-style query builder. It stores the evolving
// conditions and options before generating the final SQL statement.
pub struct Builder {
	table string
mut:
	select_fields []string
	conditions    []Bb
	sorts         []SortSpec
	limit_val     int = -1
	offset_val    int = -1
}

// of creates a Builder pointing to the given table.
pub fn of(table string) Builder {
	return Builder{
		table: table
		select_fields: []
		conditions: []
		sorts: []
	}
}

// select overrides the returned columns (defaults to "*").
pub fn (mut b Builder) select(fields ...string) &Builder {
	if fields.len > 0 {
		b.select_fields = fields.clone()
	}
	return b
}

// eq adds key = value (auto-filtering blank values).
pub fn (mut b Builder) eq[T](key string, value T) &Builder {
	return b.add_single_condition(key, '=', value)
}

// ne adds key != value.
pub fn (mut b Builder) ne[T](key string, value T) &Builder {
	return b.add_single_condition(key, '!=', value)
}

// gt adds key > value.
pub fn (mut b Builder) gt[T](key string, value T) &Builder {
	return b.add_single_condition(key, '>', value)
}

// gte adds key >= value.
pub fn (mut b Builder) gte[T](key string, value T) &Builder {
	return b.add_single_condition(key, '>=', value)
}

// lt adds key < value.
pub fn (mut b Builder) lt[T](key string, value T) &Builder {
	return b.add_single_condition(key, '<', value)
}

// lte adds key <= value.
pub fn (mut b Builder) lte[T](key string, value T) &Builder {
	return b.add_single_condition(key, '<=', value)
}

// like adds key LIKE %value%.
pub fn (mut b Builder) like(key string, value string) &Builder {
	if value.len == 0 {
		return b
	}
	return b.add_like(key, '%${value}%')
}

// like_left adds key LIKE value%.
pub fn (mut b Builder) like_left(key string, value string) &Builder {
	if value.len == 0 {
		return b
	}
	return b.add_like(key, '${value}%')
}

// in adds key IN (values...).
pub fn (mut b Builder) r#in[T](key string, values []T) &Builder {
	if values.len == 0 {
		return b
	}
	mut filtered := []any{}
	for v in values {
		if should_skip(v) {
			continue
		}
		filtered << v
	}
	if filtered.len == 0 {
		return b
	}
	b.conditions << new_condition('IN', key, filtered)
	return b
}

fn (mut b Builder) add_single_condition[T](key string, op string, value T) &Builder {
	if should_skip(value) {
		return b
	}
	b.conditions << new_condition(op, key, value)
	return b
}

fn (mut b Builder) add_like(key string, pattern string) &Builder {
	b.conditions << new_condition('LIKE', key, pattern)
	return b
}

// sort appends ORDER BY field direction.
pub fn (mut b Builder) sort(field string, direction string) &Builder {
	if field.len == 0 {
		return b
	}
	mut dir := direction.to_upper()
	if dir != 'DESC' {
		dir = 'ASC'
	}
	b.sorts << SortSpec{
		field: field
		direction: dir
	}
	return b
}

// limit applies LIMIT (ignored if value <= 0).
pub fn (mut b Builder) limit(value int) &Builder {
	if value > 0 {
		b.limit_val = value
	}
	return b
}

// offset applies OFFSET (ignored if value <= 0).
pub fn (mut b Builder) offset(value int) &Builder {
	if value > 0 {
		b.offset_val = value
	}
	return b
}

// build compiles the SQL string and ordered args.
pub fn (b Builder) build() SqlResult {
	mut fields := b.select_fields.clone()
	if fields.len == 0 {
		fields = ['*']
	}
	mut sql_parts := []string{}
	sql_parts << 'SELECT ${fields.join(', ')} FROM ${b.table}'

	mut args := []any{}
	if b.conditions.len > 0 {
		mut cond_parts := []string{}
		for cond in b.conditions {
			if cond.is_group() {
				continue
			}
			if cond.value is []any {
				list_vals := cond.value as []any
				if list_vals.len == 0 {
					continue
				}
				placeholders := repeat_placeholders(list_vals.len)
				cond_parts << '${cond.key} ${cond.op} (${placeholders})'
				for v in list_vals {
					args << v
				}
				continue
			}
			cond_parts << '${cond.key} ${cond.op} ?'
			args << cond.value
		}
		if cond_parts.len > 0 {
			sql_parts << 'WHERE ${cond_parts.join(' AND ')}'
		}
	}

	if b.sorts.len > 0 {
		mut sort_parts := []string{}
		for sort in b.sorts {
			sort_parts << '${sort.field} ${sort.direction}'
		}
		sql_parts << 'ORDER BY ${sort_parts.join(', ')}'
	}

	if b.limit_val > 0 {
		sql_parts << 'LIMIT ${b.limit_val}'
	}
	if b.offset_val > 0 {
		sql_parts << 'OFFSET ${b.offset_val}'
	}

	return SqlResult{
		sql: sql_parts.join(' ')
		args: args
	}
}

fn repeat_placeholders(count int) string {
	mut parts := []string{}
	for _ in 0 .. count {
		parts << '?'
	}
	return parts.join(', ')
}

fn should_skip[T](value T) bool {
	return match value {
		string { value.len == 0 }
		[]string { value.len == 0 }
		[]int { value.len == 0 }
		[]i64 { value.len == 0 }
		[]f64 { value.len == 0 }
		int { value == 0 }
		i64 { value == 0 }
		i32 { value == 0 }
		u32 { value == 0 }
		u64 { value == 0 }
		f32 { value == 0.0 }
		f64 { value == 0.0 }
		bool { value == false }
		none { true }
		else { false }
	}
}


[test]
fn test_basic_builder_sql() {
	mut builder := of('users')
	builder = builder
		.select('id', 'name')
		.eq('status', 'active')
		.gt('age', 18)
		.like('name', 'jo')
		.sort('created_at', 'desc')
		.limit(10)
	result := builder.build()
	assert result.sql == 'SELECT id, name FROM users WHERE status = ? AND age > ? AND name LIKE ? ORDER BY created_at DESC LIMIT 10'
	assert result.args == ['active', 18, '%jo%']
}

