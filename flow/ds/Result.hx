package flow.ds;

enum Result<T, E> {
	Ok(v:T);
	Err(e:E);
}
