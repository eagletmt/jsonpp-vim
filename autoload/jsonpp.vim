function! jsonpp#prettify(line1, line2)
  if !exists('g:jsonpp_engine')
    for l:engine in ['python3', 'python2', 'perl']
      if s:pp[l:engine].available()
        let g:jsonpp_engine = l:engine
        break
      endif
    endfor
  endif
  if exists('g:jsonpp_engine')
    call s:pp[g:jsonpp_engine].prettify(a:line1, a:line2)
  else
    throw 'jsonpp-vim: No available engine'
  endif
endfunction

let s:pp = {
      \ 'python3': {},
      \ 'python2': {},
      \ 'perl': {},
      \ }

function! s:python_prettify(line1, line2)
  python <<EOS
import vim
import json

indent = vim.vars.get('jsonpp_indent', 4)
ensure_ascii = not not vim.vars.get('jsonpp_ensure_ascii', True)
line1 = vim.bindeval('a:line1')
line2 = vim.bindeval('a:line2')

data = ''.join(vim.current.buffer.range(line1, line2))
formatted = json.dumps(json.loads(data), indent=indent, separators=(',', ': '), ensure_ascii=ensure_ascii, sort_keys=True)

buf = vim.current.buffer
del buf[line1-1 : line2]
buf.append(formatted.splitlines(), line1-1)
EOS
endfunction

function! s:pp.python3.available()
  if !has('python3')
    return 0
  endif
  try
    python3 <<EOS
import vim
import json
EOS
    return 1
  endtry
  return 0
endfunction

function! s:pp.python3.prettify(line1, line2)
  call s:python_prettify(a:line1, a:line2)
endfunction

function! s:pp.python2.available()
  if !has('python')
    return 0
  endif
  try
    python <<EOS
import vim
import json
EOS
    return 1
  endtry
  return 0
endfunction

function! s:pp.python2.prettify(line1, line2)
  call s:python_prettify(a:line1, a:line2)
endfunction

function! s:pp.perl.available()
  if !has('perl')
    return 0
  endif
  try
    perl <<EOS
use JSON::PP ();
EOS
    return 1
  endtry
  return 0
endfunction

function! s:pp.perl.prettify(line1, line2)
  perl <<EOS
use JSON::PP ();

my $indent = VIM::Eval('get(g:, "jsonpp_indent", 4)');
my $ensure_ascii = VIM::Eval('get(g:, "jsonpp_ensure_ascii", 1)');
my $line1 = VIM::Eval('a:line1');
my $line2 = VIM::Eval('a:line2');

my $json = JSON::PP->new->
  indent(1)->indent_length($indent)->
  ascii($ensure_ascii)->utf8(1)->
  space_after(1)->space_before(0)->canonical(1);

my $data = join("\n", $curbuf->Get($line1 .. $line2));
my $formatted = $json->encode($json->decode($data));

$curbuf->Delete($line1, $line2);
$curbuf->Append($line1-1, split(/\n/, $formatted));
EOS
endfunction
