%include 'inc/func.inc'
%include 'class/class_boxed_ptr.inc'

	def_function class/boxed_ptr/init
		;inputs
		;r0 = object
		;r1 = vtable pointer
		;outputs
		;r1 = 0 if error, else ok

		;init parent
		p_call boxed_ptr, init, {r0, r1}, {r1}
		if r1, !=, 0
			;init myself
			vp_cpy_cl 0, [r0 + boxed_ptr_value]
		endif
		vp_ret

	def_function_end
