package pool

import "core:log"


Dense_Pool :: struct($T: typeid, $N: int) {
	elements: [N]T,
	count:    int,
}


dense_pool_delete :: proc(pool: ^Dense_Pool($T, $N), index: int) {
	when ODIN_DEBUG {
		if index < 0 {
			log.error("Tried to index dense pool with a negative index.")
			return
		}
		if index >= pool.count {
			log.error("Tried to index dense pool outside of its bounds.")
			return
		}
	}
	last_index := pool.count - 1
	pool.elements[index] = pool.elements[last_index]
	pool.count -= 1
}

dense_pool_allocate :: proc(pool: ^Dense_Pool($T, $N)) -> ^T {
	when ODIN_DEBUG {
		if pool.count >= len(pool.elements) {
			log.error("Cannot allocate anymore in the dense pool as it is already full.")
			return nil
		}
	}
	index := pool.count
	pool.count += 1
	return &pool.elements[index]
}

dense_pool_slice :: proc(pool: ^Dense_Pool($T, $N)) -> []T {
	return pool.elements[:pool.count]
}
