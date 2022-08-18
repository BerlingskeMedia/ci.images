# drone-check-parameters

This plugin takes any parameters and exits with error if any given parameter is empty.

You can also provide regex rule to check content of parameter.

To provide regex, add additional parameter with the same name as parameter to validate but prefixed with `expected`. If regex matcher returns empty string - plugin will fail.


## Example usage:
```yaml
- image: drone-param-check
  name: check-parameters
  settings:
    # example parameters:
    param1: ${SOME_DRONE_VARIABLE}
    param2: some string
    param3:
    - some
    - list
    # Usage with secrets
    access_key:
      from_secret: aws_key
    secret_key:
      from_secret: aws_secret
    # usage to validate against regex
    param4: this is ok
    expected_param4: .+
    param5: this will fail
    expected_param5: not fail
```
