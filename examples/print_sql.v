module main

import vxb

fn main() {
	mut b := vxb.of('users')
	b.select('id', 'name')
	b.eq('status', 'active')
	b.gt('age', 18)
	b.like('name', 'jo')
	b.sort('created_at', 'desc')
	b.limit(10)
	
	built := b.build()

	sql_text, vs := built.sql_of_select()
	vs_strings := vxb.vs2str(vs)

	println('SQL => $sql_text')
	println('ARGS => $vs_strings')
}