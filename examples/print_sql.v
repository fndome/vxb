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

	sql_text, args := built.sql_of_select()
	arg_strings := args.map(vxb.scalar_to_string(it))

	println('SQL => $sql_text')
	println('ARGS => $arg_strings')
}