describe "Zepto grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-zepto")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.zepto")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.zepto"

  it "tokenizes semi-colon comments", ->
    {tokens} = grammar.tokenizeLine "; zepto"
    expect(tokens[0]).toEqual value: ";", scopes: ["source.zepto", "comment.line.semicolon.zepto", "punctuation.definition.comment.zepto"]
    expect(tokens[1]).toEqual value: " zepto", scopes: ["source.zepto", "comment.line.semicolon.zepto"]

  it "tokenizes lang definitions", ->
    {tokens} = grammar.tokenizeLine "#lang zepto"
    expect(tokens[0]).toEqual value: "#", scopes: ["source.zepto", "comment.line.semicolon.zepto", "punctuation.definition.comment.lang.zepto"]
    expect(tokens[1]).toEqual value: "/usr/bin/env zepto", scopes: ["source.zepto", "comment.line.semicolon.zepto"]

  it "tokenizes strings", ->
    {tokens} = grammar.tokenizeLine '"foo bar"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.zepto", "string.quoted.double.zepto", "punctuation.definition.string.begin.zepto"]
    expect(tokens[1]).toEqual value: 'foo bar', scopes: ["source.zepto", "string.quoted.double.zepto"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.zepto", "string.quoted.double.zepto", "punctuation.definition.string.end.zepto"]

  it "tokenizes character escape sequences", ->
    {tokens} = grammar.tokenizeLine '"\\n"'
    expect(tokens[0]).toEqual value: '"', scopes: ["source.zepto", "string.quoted.double.zepto", "punctuation.definition.string.begin.zepto"]
    expect(tokens[1]).toEqual value: '\\n', scopes: ["source.zepto", "string.quoted.double.zepto", "constant.character.escape.zepto"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.zepto", "string.quoted.double.zepto", "punctuation.definition.string.end.zepto"]

  it "tokenizes numerics", ->
    numbers =
      "constant.numeric.ratio.zepto": ["1/2", "123/456"]
      "constant.numeric.hexadecimal.zepto": ["#xDEADBEEF", "#xDEADBEEF"]
      "constant.numeric.octal.zepto": ["#o123"]
      "constant.numeric.binary.zepto": ["#b101"]
      "constant.numeric.double.zepto": ["123.45", "123.45e6", "123.45E6"]
      "constant.numeric.long.zepto": ["123", "12321"]

    for scope, nums of numbers
      for num in nums
        {tokens} = grammar.tokenizeLine num
        expect(tokens[0]).toEqual value: num, scopes: ["source.zepto", scope]

  it "tokenizes booleans", ->
    booleans =
      "constant.language.boolean.zepto": ["#t", "#f"]

    for scope, bools of booleans
      for bool in bools
        {tokens} = grammar.tokenizeLine bool
        expect(tokens[0]).toEqual value: bool, scopes: ["source.zepto", scope]

  it "tokenizes keywords", ->
    tests =
      "meta.expression.zepto": ["(:foo)"]
      "meta.map.zepto": ["\#{:foo}"]
      "meta.vector.zepto": ["{:foo}"]
      "meta.quoted-expression.zepto": ["'(:foo)", "`(:foo)"]

    for metaScope, lines of tests
      for line in lines
        {tokens} = grammar.tokenizeLine line
        expect(tokens[1]).toEqual value: ":foo", scopes: ["source.zepto", metaScope, "constant.keyword.zepto"]

  it "tokenizes keyfns (keyword control)", ->
    keyfns = ["module", "import", "import-all", "load", "define", "define-syntax", "define-struct", "defimpl", "defprotocol"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.zepto", "meta.expression.zepto", "keyword.control.zepto"]

  it "tokenizes keyfns (storage control)", ->
    keyfns = ["if", "when", "for", "cond", "do", "let", "lambda", "case"]

    for keyfn in keyfns
      {tokens} = grammar.tokenizeLine "(#{keyfn})"
      expect(tokens[1]).toEqual value: keyfn, scopes: ["source.zepto", "meta.expression.zepto", "storage.control.zepto"]

  it "tokenizes global definitions", ->
    {tokens} = grammar.tokenizeLine "(define foo 'bar)"
    expect(tokens[1]).toEqual value: "define", scopes: ["source.zepto", "meta.expression.zepto", "meta.definition.global.zepto", "keyword.control.zepto"]
    expect(tokens[3]).toEqual value: "foo", scopes: ["source.zepto", "meta.expression.zepto", "meta.definition.global.zepto", "entity.global.zepto"]

  it "tokenizes functions", ->
    expressions = ["(foo)", "(foo 1 10)"]

    for expr in expressions
      {tokens} = grammar.tokenizeLine expr
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.zepto", "meta.expression.zepto", "entity.name.function.zepto"]

  it "tokenizes symbols", ->
    {tokens} = grammar.tokenizeLine "foo/bar"
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.zepto", "meta.symbol.namespace.zepto"]
    expect(tokens[1]).toEqual value: "/", scopes: ["source.zepto"]
    expect(tokens[2]).toEqual value: "bar", scopes: ["source.zepto", "meta.symbol.zepto"]

  it "tokenizes trailing whitespace", ->
    {tokens} = grammar.tokenizeLine "   \n"
    expect(tokens[0]).toEqual value: "   \n", scopes: ["source.zepto", "invalid.trailing-whitespace"]

  testMetaSection = (metaScope, puncScope, startsWith, endsWith) ->
    # Entire expression on one line.
    {tokens} = grammar.tokenizeLine "#{startsWith}foo, bar#{endsWith}"

    [start, mid..., end, after] = tokens

    expect(start).toEqual value: startsWith, scopes: ["source.zepto", "meta.#{metaScope}.zepto", "punctuation.section.#{puncScope}.begin.zepto"]
    expect(end).toEqual value: endsWith, scopes: ["source.zepto", "meta.#{metaScope}.zepto", "punctuation.section.#{puncScope}.end.zepto"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.zepto", "meta.#{metaScope}.zepto"]

    # Expression broken over multiple lines.
    tokens = grammar.tokenizeLines("#{startsWith}foo\n bar#{endsWith}")

    [start, mid..., after] = tokens[0]

    expect(start).toEqual value: startsWith, scopes: ["source.zepto", "meta.#{metaScope}.zepto", "punctuation.section.#{puncScope}.begin.zepto"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.zepto", "meta.#{metaScope}.zepto"]

    [mid..., end, after] = tokens[1]

    expect(end).toEqual value: endsWith, scopes: ["source.zepto", "meta.#{metaScope}.zepto", "punctuation.section.#{puncScope}.end.zepto"]

    for token in mid
      expect(token.scopes.slice(0, 2)).toEqual ["source.zepto", "meta.#{metaScope}.zepto"]

  it "tokenizes expressions", ->
    testMetaSection "expression", "expression", "(", ")"

  it "tokenizes quoted expressions", ->
    testMetaSection "quoted-expression", "expression", "'(", ")"
    testMetaSection "quoted-expression", "expression", "`(", ")"

  it "tokenizes vectors", ->
    testMetaSection "vector", "vector", "{", "}"

  it "tokenizes maps", ->
    testMetaSection "map", "map", "\#{", "}"

  it "tokenizes functions in nested sexp", ->
    {tokens} = grammar.tokenizeLine "((foo bar) baz)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.zepto", "meta.expression.zepto", "punctuation.section.expression.begin.zepto"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.zepto", "meta.expression.zepto", "meta.expression.zepto", "punctuation.section.expression.begin.zepto"]
    expect(tokens[2]).toEqual value: "foo", scopes: ["source.zepto", "meta.expression.zepto", "meta.expression.zepto", "entity.name.function.zepto"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.zepto", "meta.expression.zepto", "meta.expression.zepto"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.zepto", "meta.expression.zepto", "meta.expression.zepto", "meta.symbol.zepto"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.zepto", "meta.expression.zepto", "meta.expression.zepto", "punctuation.section.expression.end.zepto"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.zepto", "meta.expression.zepto"]
    expect(tokens[7]).toEqual value: "baz", scopes: ["source.zepto", "meta.expression.zepto", "meta.symbol.zepto"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.zepto", "meta.expression.zepto", "punctuation.section.expression.end.zepto"]

  it "tokenizes maps used as functions", ->
    {tokens} = grammar.tokenizeLine "(\#{:foo bar} :foo)"
    expect(tokens[0]).toEqual value: "(", scopes: ["source.zepto", "meta.expression.zepto", "punctuation.section.expression.begin.zepto"]
    expect(tokens[1]).toEqual value: "\#{", scopes: ["source.zepto", "meta.expression.zepto", "meta.map.zepto", "punctuation.section.map.begin.zepto"]
    expect(tokens[2]).toEqual value: ":foo", scopes: ["source.zepto", "meta.expression.zepto", "meta.map.zepto", "constant.keyword.zepto"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.zepto", "meta.expression.zepto", "meta.map.zepto"]
    expect(tokens[4]).toEqual value: "bar", scopes: ["source.zepto", "meta.expression.zepto", "meta.map.zepto", "meta.symbol.zepto"]
    expect(tokens[5]).toEqual value: "}", scopes: ["source.zepto", "meta.expression.zepto", "meta.map.zepto", "punctuation.section.map.end.zepto"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.zepto", "meta.expression.zepto"]
    expect(tokens[7]).toEqual value: ":foo", scopes: ["source.zepto", "meta.expression.zepto", "constant.keyword.zepto"]
    expect(tokens[8]).toEqual value: ")", scopes: ["source.zepto", "meta.expression.zepto", "punctuation.section.expression.end.zepto"]
