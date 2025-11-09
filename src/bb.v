module vxb

// Bb (Building Block) captures a single condition or a compound expression.
pub struct Bb {
	pub:
		op   string
		key  string
		value any
		subs []Bb
}

// condition creates a simple leaf node (e.g. key = value).
pub fn new_condition(op string, key string, value any) Bb {
	return Bb{
		op: op
		key: key
		value: value
		subs: []Bb{}
	}
}

// compound creates a grouped node (e.g. AND (...), OR (...)).
pub fn new_compound(op string, subs []Bb) Bb {
	return Bb{
		op: op
		key: ''
		value: none
		subs: subs.clone()
	}
}

// is_group tells whether this Bb is a compound node.
pub fn (bb Bb) is_group() bool {
	return bb.subs.len > 0
}

// with_subs returns a copy replacing subs (useful for builder transformations).
pub fn (bb Bb) with_subs(subs []Bb) Bb {
	return Bb{
		...bb
		subs: subs.clone()
	}
}

// --- Tests -----------------------------------------------------------------

[test]
fn test_bb_condition() {
	bb := new_condition('=', 'name', 'Alice')
	assert bb.op == '='
	assert bb.key == 'name'
	assert !bb.is_group()
}

[test]
fn test_bb_compound() {
	sub1 := new_condition('=', 'status', 1)
	sub2 := new_condition('>', 'age', 18)
	group := new_compound('AND', [sub1, sub2])
	assert group.is_group()
	assert group.subs.len == 2
	assert group.op == 'AND'
}

