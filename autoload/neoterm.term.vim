let g:neoterm.term = {}

function! g:neoterm.term.new(id, handlers)
  let name = ";#neoterm-".a:id
  let instance = extend(copy(self), {
        \ "id": a:id,
        \ })

  let instance.handlers = a:handlers

  let instance.job_id = termopen(g:neoterm_shell . name, instance)
  let instance.buffer_id = bufnr("")

  return instance
endfunction

function! g:neoterm.term.mappings()
  if has_key(g:neoterm.instances, self.id)
    let instance = "g:neoterm.instances.".self.id
    exec "command! -complete=shellcmd Topen".self.id." silent call ".instance.".open()"
    exec "command! -complete=shellcmd Tclose".self.id." silent call ".instance.".close()"
    exec "command! -complete=shellcmd Tclear".self.id." silent call ".instance.".clear()"
    exec "command! -complete=shellcmd Tkill".self.id." silent call ".instance.".kill()"
    exec "command! -complete=shellcmd -nargs=+ T".self.id." silent call ".instance.".do(<q-args>)"
  else
    echoe "There is no ".self.id." neoterm."
  end
endfunction

function! g:neoterm.term.open()
  let current_window = g:neoterm.split()

  exec "buffer " . self.buffer_id

  if g:neoterm_keep_term_open
    silent exec current_window . "wincmd w | set noinsertmode"
  else
    startinsert
  end
endfunction

function! g:neoterm.term.close()
  if bufwinnr(self.buffer_id) > 0
    exec bufwinnr(self.buffer_id) . "hide"
  end
endfunction

function! g:neoterm.term.do(command)
  call self.exec([a:command, ""])
endfunction

function! g:neoterm.term.exec(command)
  call jobsend(self.job_id, a:command)
endfunction

function! g:neoterm.term.clear()
  call self.exec("\<c-l>")
endfunction

function! g:neoterm.term.kill()
  call self.exec("\<c-c>")
endfunction

function! g:neoterm.term.on_stdout(job_id, data, event)
  if has_key(self.handlers, "on_stdout")
    call self.handlers["on_stdout"](a:job_id, a:data, a:event)
  end
endfunction

function! g:neoterm.term.on_stderr(job_id, data, event)
  if has_key(self.handlers, "on_stderr")
    call self.handlers["on_stderr"](a:job_id, a:data, a:event)
  end
endfunction

function! g:neoterm.term.on_exit(job_id, data, event)
  if has_key(self.handlers, "on_exit")
    call self.handlers["on_exit"](a:job_id, a:data, a:event)
  end

  call self.destroy()
endfunction

function! g:neoterm.term.destroy()
  if has_key(g:neoterm, "repl") && get(g:neoterm.repl, "instance_id") == self.id
    call remove(g:neoterm.repl, "instance_id")
  end

  if has_key(g:neoterm, "test") && get(g:neoterm.test, "instance_id") == self.id
    call remove(g:neoterm.test, "instance_id")
  end

  if has_key(g:neoterm.instances, self.id)
    call remove(g:neoterm.instances, self.id)
  end
endfunction
