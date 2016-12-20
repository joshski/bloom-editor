_ = require 'underscore'
hyperdom = require 'hyperdom'
h = hyperdom.html
hello = require './helloWorld'

module.exports () =

  model = {
    code = hello()
    selectedNode = nil

    selectNode(node) =
      if (self.selectedNode)
        self.selectedNode.selected = false

      if (node)
        node.selected = true

      self.selectedPath = pathToNodeWithin (node, self.code)
      self.selectedNode = node
  }

  pathToNodeWithin (node, parent) =
    children = []
    for @(key) in (parent)
      value = parent.(key)
      if ((value :: Object) @and (value.type :: String))
        children.push (value)

      if (value :: Array)
        for each @(item) in (value)
          if ((item :: Object) @and (item.type :: String))
            children.push (item)

    p = nil
    for each @(child) in (children)
      if (child == node)
        p := node
      else
        p := p @or (pathToNodeWithin (node, child))

    if (p)
      [parent].concat(p)
    else
      nil

  selectable (node, name, args, apply) =
    opts = {
      onclick (e) =
        model.selectNode (node)
        e.stopPropagation()
    }
    if (args.0 :: Object)
      args.0.onclick = opts.onclick
    else
      args := [opts].concat(args)

    selector = "div.#(name)"
    if (node.selected)
      selector := "#(selector).selected"

    args := [selector].concat(args)
    apply(args)

  e (node, name, args, ...) =
    selectable (node, name, args) @(a)
      h.apply (hyperdom, a)

  r (node, name, args, ...) =
    selectable (node, name, args) @(a)
      h.rawHtml.apply (hyperdom, a)

  terms = {

    Program = {
      render (node) =
        e (node) 'program' (
          [
            child <- node.body
            e (node) 'line' (renderNode (child))
          ]
          ...
        )

      commandsFor (me, node) =
        [
          if (me == node)
            {
              name = 'Add Statement'
              icon = 'plus'
              execute () =
                model.selectNode (nil)
                newNode = { type = 'Undefined' }
                me.body.push (newNode)
                model.selectNode (newNode)
            }

          if (me.body.indexOf (node) > -1)
            {
              name = 'Delete'
              icon = 'remove'
              execute () =
                me.body = _.without(me.body, node)
                model.selectNode (nil)
            }

          if (me.body.indexOf (node) > -1)
            {
              name = 'Add Statement After'
              icon = 'plus'
              execute () =
                model.selectNode (nil)
                newNode = { type = 'Undefined' }
                me.body.splice (me.body.indexOf (node) + 1, 0, newNode)
                model.selectNode (newNode)
            }

          if (me.body.indexOf (node) > -1)
            {
              name = 'Insert Statement Before'
              icon = 'minus'
              execute () =
                model.selectNode (nil)
                newNode = { type = 'Undefined' }
                me.body.splice (me.body.indexOf (node), 0, newNode)
                model.selectNode (newNode)
            }


          if ((me == node) @and (me.body.length > 0))
            {
              name = 'Delete All'
              icon = 'trash'
              execute () =
                me.body = []
            }
        ]
    }

    Identifier = {
      render (node) =
        e (node) 'identifier' {
          class = { empty = node.name.length == 0 }
        } (node.name)

      editor (node) =
        h 'div.identifier-editor' (
          h 'label' { for = 'identifier_name' } 'Name'
          h 'input#identifier_name' {
            type = 'text'
            attributes = {
              autocapitalize = 'none'
              autocorrect = 'off'
              autofocus = 'autofocus'
            }
            binding = [node, 'name']
          }
        )

      commandsFor (me, node) =
        [
          memberCommandFor (node)
          callMemberCommandFor (node)
          {
            name = 'Assign'
            icon = 'briefcase'
            execute () =
              model.selectNode(nil)
              oldNode = JSON.stringify(node)
              undefineNode (node)
              node.type = 'Assignment'
              node.left = JSON.parse(oldNode)
              node.right = { type = 'Undefined' }
              model.selectNode(node.right)
          }
        ]
    }

    Assignment = {
      render (node) =
        e (node) 'assignment' (
          renderNode (node.left)
          h.rawHtml 'span.whitespace' '&nbsp;'
          e (node) 'equals' '='
          r (node) 'whitespace' '&nbsp;'
          renderNode (node.right)
        )

      commandsFor (me, node) =
        [
        ]
    }

    BlankLine = {
      render (node) =
        e (node) 'blank-line'

      commandsFor (me, node) =
        [
        ]
    }

    FunctionDeclaration = {
      render (node) =
        e (node) 'function-declaration' (
          e (node) 'function-signature' (
            e (node) 'function-name' (node.name)
            e (node) 'whitespace' (h.rawHtml('span', '&nbsp;'))
            e (node) 'bracket.open' '('
            e (node) 'bracket.close' ')'
            r (node) 'whitespace' '&nbsp;'
            e (node) 'equals' '='
          )
          e (node) 'function-body' (
            [
              child <- node.body
              e (node) 'line' (renderNode (child))
            ]
            ...
          )
        )

      editor (node) =
        h 'div.function-declaration-editor' (
          h 'label' { for = 'function_declaration_name' } 'Name'
          h 'input#function_declaration_name' {
            type = 'text'
            attributes = {
              autocapitalize = 'none'
              autocorrect = 'off'
              autofocus = 'autofocus'
            }
            binding = [node, 'name']
          }
        )

      commandsFor (me, node) =
        commands = []

        bodyIndex = me.body.indexOf(node)

        if (bodyIndex > -1)
          commands.push {
            name = 'Delete'
            icon = 'trash'
            execute () =
              model.selectNode (nil)
              me.body.splice (bodyIndex, 1)
          }

        if (me == node)
          commands.push {
            name = 'Append to Body'
            icon = 'plus'
            execute () =
              model.selectNode (nil)
              newNode = { type = 'Undefined' }
              me.body.push (newNode)
              model.selectNode (newNode)
          }

        commands
    }

    CallExpression = {
      render (node) =
        e (node) 'call-expression' (
          renderNode (node.callee)
          r (node) 'whitespace' '&nbsp;'
          e (node) 'bracket.open' ' ('
          renderArguments (node.arguments)
          e (node) 'bracket.close' ')'
        )

      commandsFor (me, node) =
        argumentIndex = me.arguments.indexOf(node)
        commands = []

        if (me == node)
          commands := commands.concat [
            {
              name = 'Add Argument'
              icon = 'arrow-right'
              execute () =
                newNode = { type = 'Undefined' }
                me.arguments.push(newNode)
            }
            {
              name = 'Insert Argument'
              icon = 'arrow-left'
              execute () =
                newNode = { type = 'Undefined' }
                me.arguments.splice(0, 0, newNode)
            }
            redefineCommandFor (node)
          ]

        if (argumentIndex > -1)
          commands := commands.concat [
            {
              name = 'Add After'
              icon = 'arrow-right'
              execute () =
                model.selectNode (nil)
                newNode = { type = 'Undefined' }
                me.arguments.push(newNode)
                model.selectNode (newNode)
            }
            {
              name = 'Insert Before'
              icon = 'arrow-left'
              execute () =
                model.selectNode (nil)
                newNode = { type = 'Undefined' }
                me.arguments.splice(argumentIndex, 0, newNode)
                model.selectNode (newNode)
            }
            {
              name = 'Delete'
              icon = 'remove'
              execute () =
                me.arguments.splice (argumentIndex, 1)
                model.selectNode (nil)
            }
          ]

        commands
    }

    MemberExpression = {
      render (node) =
        e (node) 'member-expression' (
          renderNode (node.object)
          e (node) 'dot' '.'
          renderNode (node.property)
        )

      commandsFor (me, node) =
        [
          redefineCommandFor (node)
        ]
    }

    Literal = {
      render (node) =
        e (node) 'literal' ("'", node.value, "'")

      editor (node) =
        h 'div.literal-editor' (
          h 'label' { for = 'literal_value' } 'Value'
          h 'input#literal_value' {
            type = 'text'
            binding = [node, 'value']
            attributes = {
              autocapitalize = 'none'
              autocorrect = 'off'
              autofocus = 'autofocus'
            }
          }
        )

      commandsFor (me, node) =
        [
          redefineCommandFor (node)
          memberCommandFor (node)
          callMemberCommandFor (node)
        ]
    }

    Undefined = {
      render (node) =
        e (node) 'undefined' 'undefined'

      commandsFor (me, node) =
        if (me == node)
          [
            {
              name = 'Literal'
              icon = 'font'
              execute () =
                node.type = 'Literal'
                node.value = ''
            }
            {
              name = 'Identifier'
              icon = 'italic'
              execute () =
                node.type = 'Identifier'
                node.name = ''
                node.value = 'id'
            }
            {
              name = 'Function'
              icon = 'gear'
              execute () =
                node.type = 'FunctionDeclaration'
                node.name = 'fn'
                node.body = [{ type = 'Undefined' }]
            }
          ]
    }

  }

  undefineNode (node) =
    for each @(key) in (_.keys(node))
      delete (node.(key))

    node.type = 'Undefined'
    model.selectNode (nil)
    model.selectNode (node)

  redefineCommandFor (node) = {
    name = 'Redefine'
    icon = 'refresh'
    execute () =
      undefineNode (node)
      model.selectNode (nil)
      model.selectNode (node)
  }

  memberCommandFor (node) = {
    name = 'Member'
    icon = 'square-o'
    execute () =
      model.selectNode (nil)
      oldNode = JSON.stringify(node)

      for each @(key) in (_.keys(node))
        delete (node.(key))

      node.type = "MemberExpression"
      node.object = JSON.parse(oldNode)
      node.property = {
        type = "Identifier"
        name = "member"
      }
      model.selectNode (node.property)
  }

  callMemberCommandFor (node) = {
    name = 'Call Member'
    icon = 'comment-o'
    execute () =
      model.selectNode (nil)
      oldNode = JSON.stringify(node)

      for each @(key) in (_.keys(node))
        delete (node.(key))

      node.type = "CallExpression"
      node.callee = {
        type = "MemberExpression"
        object = JSON.parse(oldNode)
        property = {
          type = "Identifier"
          name = "member"
        }
      }
      node.arguments = []
      model.selectNode (node.callee.property)
  }

  renderNode (node) =
    term = terms.(node.type)
    if (@not term)
      throw (new (Error "Term type #(node.type) unsupported"))

    term.render (node)

  renderArguments (args) =
    renderNodes 'span.arguments' (args)

  renderNodes (selector, nodes) =
    h (
      selector
      insertCommasBetween [n <- nodes, renderNode (n)]
      ...
    )

  insertCommasBetween (nodes) =
    withCommas = []
    for (i = 0, i < nodes.length, i := i + 1)
      if ((i > 0) @and (i < nodes.length))
        withCommas.push (e (nodes.(i)) 'span.comma' ',')
        withCommas.push (r (nodes.(i)) 'whitespace' '&nbsp;')

      withCommas.push (nodes.(i))

    withCommas

  commandsFor (node) =
    path = pathToNodeWithin (node, model.code)
    commands = []
    if (path)
      path.reverse ()
      for each @(crumb) in (path)
        term = terms.(crumb.type)
        commands := commands.concat(term.commandsFor(crumb, node))
    else
      commands := terms.(node.type).commandsFor (node, node)

    [cmd <- commands, cmd, cmd]

  render (model) =

    crumbItem (crumb) =
      e (crumb) 'crumb' (
        e (crumb) 'text' (crumb.type)
      )

    h 'div.frames' (
      h 'div.header-frame'
      h 'div.crumbtrail-frame' (
        h 'div.crumbtrail' (
          if (model.selectedPath)
            model.selectedPath.map (crumbItem)
          else
            crumbItem (model.code)
        )
      )
      h 'div.code-frame' {
        onclick () = model.selectNode(nil)
      } (
        renderNode (model.code)
      )
      h 'div.navigation-frame' (
        if (model.selectedNode)
          term = terms.(model.selectedNode.type)

          [
            h 'h2' (model.selectedNode.type)

            if (term.editor)
              h 'div.editor' (
                term.editor(model.selectedNode)
              )

            h 'ul' (
              commandsFor(model.selectedNode).map @(cmd)
                h 'li' (
                  h 'a' {
                    class = cmd.name.toLowerCase().replace(' ', '-')
                    href = "##(cmd.name)"
                    onclick (e) =
                      e.preventDefault()
                      result = cmd.execute()
                  } (
                    h "span.fa.fa-#(cmd.icon)"
                    cmd.name
                  )
                )
            )
          ]
      )
    )

  {
    render = render
    model = model
  }
