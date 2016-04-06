'.source.zepto':
  'module':
    'prefix': 'module'
    'body': """
      (module ${1:name}
        (export ${2:functions})
        $0)
    """

  'define':
    'prefix': 'define'
    'body': '(define ${1:symbol} ${2:value})'

  'lambda':
    'prefix': 'lambda'
    'body': """
      (lambda ()${1:params})
        ${2:body})$0
    """

  'let':
    'prefix': 'let'
    'body': """
      (let (${1:bindings})
        ${2:body})
    """

  'let*':
    'prefix': 'let*'
    'body': """
      (let* (${1:bindings})
        ${2:body})
    """

  'letrec':
    'prefix': 'letrec'
    'body': """
      (letrec (${1:bindings})
        ${2:body})
    """

    'letrec*':
      'prefix': 'letrec*'
      'body': """
        (letrec* (${1:bindings})
          ${2:body})
      """

  'if':
    'prefix': 'if'
    'body': """
      (if ${1:test}
        ${2:then}
        ${3:else})
    """

  'map':
    'prefix': 'map'
    'body': '(map $1 $2)'

  'display':
    'prefix': 'display'
    'body': '(display $1)'

  'write':
    'prefix': 'write'
    'body': '(write $1)'
