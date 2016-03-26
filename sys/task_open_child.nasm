%include 'inc/func.inc'
%include 'inc/task.inc'

	fn_function sys/task_open_child, no_debug_enter
		;inputs
		;r0 = new task function name
		;outputs
		;r0, r1 = new task mailbox ID
		;trashes
		;r2-r3, r5-r6

		static_bind sys_task, statics, r1
		vp_cpy [r1 + tk_statics_cpu_id], r1
		static_jmp sys_task, remote

	fn_function_end
