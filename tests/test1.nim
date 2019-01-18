import unittest, macros

import wspkg/private/main_impl

# sample from https://github.com/nim-lang/Nim/blob/master/examples/tunit.nim

suite "my suite1": 
  setup:
    echo "before test"

  teardown:
    echo "after test"

  test "call method1":
    echo "call method1"
    check:
      true == true
      
