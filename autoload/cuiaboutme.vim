function! cuiaboutme#Complete(arglead, cmdline, cursorpos)
  let res = webapi#http#get('http://cui-about.me/users')
  return filter(split(res.content, "\n"), 'stridx(v:val, a:arglead)==0')
endfunction

function! cuiaboutme#Show(user)
  let res = webapi#http#get(printf('http://cui-about.me/%s', a:user))
  
  let name = 'cui-about.me:'.a:user
  let winnum = bufwinnr(bufnr(name))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split '.name
  endif
  setlocal buftype=acwrite bufhidden=delete noswapfile
  let old_undolevels = &undolevels
  set undolevels=-1
  silent %d _
  call setline(1, split(res.content, "\n"))
  let &undolevels = old_undolevels
  setlocal nomodified
  1
  exe "au! BufWriteCmd <buffer> call cuiaboutme#Update('".a:user."')"
endfunction

function! cuiaboutme#Data()
  let data = {}
  for line in getline(1, '$')
    let m = matchlist(line, '^\([^= ]\+\)\s*=\s*\(.*\)\s*$')
    let data[m[1]] = m[2]
  endfor
  return data
endfunction

function! cuiaboutme#Update(user)
  let data = cuiaboutme#Data()
  let password = inputsecret(printf('Password for %s: ', a:user))
  if len(password) == 0
    return
  endif
  let data["password"] = password
  call remove(data, 'name')
  let res = webapi#http#post(printf('http://cui-about.me/%s', a:user), data, {}, 'PUT')
  let status = split(res.header[0], '\s')[1]
  if status =~ '^2'
    redraw | echomsg 'Done'
  else
    let status = matchstr(status, '^\d\+\s*\zs.*')
    echohl ErrorMsg | echomsg 'Failed: '.status | echohl None
  endif
endfunction
