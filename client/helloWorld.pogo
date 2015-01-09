module.exports () = {
  type = "Program"
  body = [
    {
      type = "Assignment"
      left = {
        type = "Identifier"
        name = "message"
      }
      right = {
        type = "Literal"
        value = "hello, world"
      }
    }
    {
      type = "BlankLine"
    }
    {
      type = "FunctionDeclaration"
      name = "hello"
      params = []
      body = [
        {
          type = "CallExpression"
          callee = {
            type = "MemberExpression"
            object = {
              type = "Identifier"
              name = "console"
            }
            property = {
              type = "Identifier"
              name = "log"
            }
          }
          arguments = [
            {
              type = "Identifier"
              name = "message"
            }
          ]
        }
      ]
    }
    {
      type = "CallExpression"
      callee = {
        type = "Identifier"
        name = "hello"
      }
      arguments = []
    }
  ]
}