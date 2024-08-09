# Bach 单元测试框架

[![Build Status](https://travis-ci.org/bach-sh/bach.svg)](https://travis-ci.org/bach-sh/bach)
[![GitHub Actions](https://github.com/bach-sh/bach/workflows/Testing%20Bach/badge.svg)](https://github.com/bach-sh/bach)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![License: MPL v2](https://img.shields.io/badge/License-MPL%20v2-blue.svg)](https://www.mozilla.org/en-US/MPL/2.0/)

[![Run on Repl.it](https://repl.it/badge/github/bach-sh/bach)](https://repl.it/github/bach-sh/bach)

Bach is a [Bash](https://www.gnu.org/software/bash/) testing framework, can be used to test scripts that contain dangerous commands like `rm -rf /`. No surprises, no pain.

[Bach](https://bach.sh) 是一个 Bash 脚本测试框架，可以用来测试包含了类似 `rm -rf /` 这样危险命令的脚本，不会给你惊喜，不会让你感到痛苦。

- 网站: https://bach.sh
- 代码: https://github.com/bach-sh/bach
- [See the English version of this document](README.md)

## Bach 入门

Bach 单元测试框架作为一个真正的 Bash 脚本的单元测试框架，意味着任何在 PATH 环境变量中的命令都成为了被测的 Bash 脚本的外部依赖，这些外部命令都不会被真正的执行。换句话说，在 Bach 的测试中，除了部分的内置命令外，所有的命令都是 "Dry Run" 的。所以，在 Bach 中，验证的是命令被执行的时候是否使用了期望的参数，而非验证命令的执行结果。毕竟，我们测试的是 Bash 脚本的行为，而非测试那些命令是否可以正常工作。Bach 也提供了一系列的 API 可以用于模拟命令的执行。

### Bach 的依赖

Bach 需要 Bash v4.3 或更高版本。在 GNU/Linux 上还需要 Coreutils 和 Diffutils，在常用的发行版中都已经默认安装好了。Bach 在 Linux/macOS/Cygwin/Git Bash/FreeBSD 等操作系统或者运行环境中验证通过。

- [Bash](https://www.gnu.org/software/bash/) v4.3+
- [Coreutils](https://www.gnu.org/software/coreutils/coreutils.html) (*GNU/Linux*)
- [Diffutils](https://www.gnu.org/software/diffutils/diffutils.html) (*GNU/Linux*)

### 安装 Bach

Bach 的安装很简单，只需要下载 [bach.sh](https://github.com/bach-sh/bach/raw/master/bach.sh) 到你的项目中，在测试脚本中用 `source` 命令导入 Bach 框架的 `bach.sh` 即可。

比如：

    source path/to/bach.sh

#### 一个简单的测试示例

    #!/usr/bin/env bash
    source bach.sh

    test-rm-rf() {
        # Bach 的标准测试用例是由两个方法组成
        #   - test-rm-rf
        #   - test-rm-rf-assert
        # 这个方法 `test-rm-rf` 是测试用例的执行

        project_log_path=/tmp/project/logs
        rm -rf "$project_log_ptah/" # 注意，这里有个笔误！
    }
    test-rm-rf-assert() {
        # 这个方法 `test-rm-rf-assert` 是测试用例的验证
        rm -rf /   # 这就是真实的将会执行的命令
                   # 不要慌！使用 Bach 测试框架不会让这个命令真的执行！
    }

    test-rm-your-dot-git() {
        # 模拟 `find` 命令来查找你的主目录下的所有 `.git` 目录，假设会找到两个目录

        @mock find ~ -type d -name .git === @stdout ~/src/your-awesome-project/.git \
                                                    ~/src/code/.git

        # 开始执行！删除你的主目录下的所有 `.git` 目录！
        find ~ -type d -name .git | xargs -- rm -rf
    }
    test-rm-your-dot-git-assert() {
        # 验证在 `test-rm-your-dot-git` 这个测试执行方法中最终是否会执行以下这个命令。

        rm -rf ~/src/your-awesome-project/.git ~/src/code/.git
    }

更多的测试示例请看 [tests/bach-testing-framework.test.sh](tests/bach-testing-framework.test.sh)

#### Windows
shebang 得是
```
#!/bin/bash
```
而非
```
#!/bin/sh
```

若以 Cygwin 而非 Git Bash 运行，要将 `bach.sh` 的行尾序列改为 `LF`.

### 用 Bach 来写脚本测试

与我们所熟悉的测试框架不同的是，Bach 的标准测试用例是由两个方法组成，这样做的目的是为了让测试用例的验证变得简单。测试用例的执行部分是写在以 `test-` 开头的方法中，然后 Bach 会寻找与这个测试方法名称对应的以 `-assert` 结尾的测试验证方法。所以，每一个 Bach 的测试执行方法都必须不能以 `-assert` 作为后缀。比如，一个名为 `test-rm-rf` 的测试执行方法，对应的测试验证方法是 `test-rm-rf-assert`。

例子：

    source bach.sh

    test-rm-rf() {
        project_log_path=/tmp/project/logs
        sudo rm -rf "$project_log_ptah/" # 这里写错了变量名，Bash 默认让变量变成空字符串，这可能是个严重的问题！
    }
    test-rm-rf-assert() {
        sudo rm -rf /
    }

Bach 会分别运行两个方法，去验证两个方法中执行的命令及其参数是否是一致的。第一个方法 `test-rm-rf` 是 Bach 的测试用例的执行，与之对应的测试验证方法就是 `test-rm-rf-assert` 这个方法

如果 Bach 没有找到某个测试用例的测试验证方法，Bach 会尝试用传统的一个测试方法的形式。在这种方式下，测试执行方法里面必须要有断言 API 的调用，否则改测试一定会失败。

例子：

    test-single-function-style() {
        declare i=2
        @assert-equals 4 "$((i*2))"
    }

Bach 的断言 API 有：

- `@assert-equals`
- `@assert-fail`
- `@assert-success`

如果 Bach 没有找到对应的测试验证方法，同时在测试执行方法里面也没有断言的调用，这个测试用例就一定是失败的。

如果一个测试用例的方法名称是以 `test-ASSERT-FAIL` 开头，则意味着反转这个测试用例的执行结果。也就是说，如果测试验证成功，反而结果是失败的。如果测试验证失败，则结果是成功的。

### 用 Bach 来模拟命令的调用

Bach 测试框架中有一系列的 Mock API，可以用于模拟命令和脚本的执行。

Mock API 有：

- `@mock`
- `@ignore`
- `@mockall`
- `@mocktrue`
- `@mockfalse`
- `@@mock`

但是仍然有个别内建命令是不允许 mock 的，有：

- `builtin`
- `declare`
- `eval`
- `set`
- `unset`
- `true`
- `false`
- `read`

如果在测试用例的执行中，试图去模拟这些被禁止模拟的内建命令，测试用例一定会失败的。对于这种情况，通常的解决办法是，把这些被禁止模拟的内建命令用一个方法包装起来，然后用 Bach 来模拟这个方法。

### 在 Bach 的测试用例中调用真实的命令

在测试用例中，为了能够稳定的、重复的、随机的执行测试用例，同时也是为了写出单元测试，我们通常要避免直接调用外部命令。但 Bach 也提供了一系列的 API 用于直接执行命令。

因为 Bach 中可以模拟几乎所有的命令，而且 Bach 的实现代码里面也一定会执行这些真实的命令。如果不可避免的要在测试用例中执行真实的命令，Bach 提供了名为 `@real` 的 API 来执行真实命令。只要在希望执行的命令前面加上 `@real` 就可以跳过 Bach 的限制。

Bach 也提供了一些常用命令的 API，这些 API 对应的真实命令都是在 Bach 启动之前从系统的 PATH 环境变量中获取的，有：

- `@cd`
- `@command`
- `@echo`
- `@exec`
- `@false`
- `@popd`
- `@pushd`
- `@pwd`
- `@set`
- `@trap`
- `@true`
- `@type`
- `@unset`
- `@eval`
- `@source`
- `@cat`
- `@chmod`
- `@cut`
- `@diff`
- `@find`
- `@env`
- `@grep`
- `@ls`
- `@shasum`
- `@mkdir`
- `@mktemp`
- `@rm`
- `@rmdir`
- `@sed`
- `@sort`
- `@tee`
- `@touch`
- `@which`
- `@xargs`

由于 `command` 和 `xargs` 命令的特殊性，Bach 中很特别的为这两个命令做了模拟。

因为 Bach 中的模拟命令的实现都是采用创建同名函数的方式，所以用 `command` 命令是无法执行这些被模拟的命令的，`@command` 这个 API 则会根据后面的命令的类型来决定行为。

而 `@xargs` 中，则真的会调用系统中的 `xargs` 命令，但默认也不会真的执行命令。

例如：

    test-xargs-no-dash-dash() {
        @mock ls === @stdout foo bar

        ls | xargs -n1 rm -v
    }
    test-xargs-no-dash-dash-assert() {
        xargs -n1 rm -v
    }


    test-xargs() {
        @mock ls === @stdout foo bar

        ls | xargs -n1 -- rm -v
    }
    test-xargs-assert() {
        rm -v foo
        rm -v bar
    }


    test-xargs-0() {
        @mock ls === @stdout foo bar

        ls | xargs -- rm -v
    }
    test-xargs-0-assert() {
        rm -v foo bar
    }

我们还可以模拟测试命令 `[ ... ]`。但如果没有模拟的话，测试将会保持原有的行为。

例如:

    test-if-string-is-empty() {
        if [ -n "original behavior" ] # 没有模拟这个测试，将保持默认行为
        then
            It keeps the original behavior by default # 应该看到这一行
        else
            It should not be empty
        fi

        @mockfalse [ -n "Non-empty string" ] # 我们可以通过模拟一个测试来反转其结果

        if [ -n "Non-empty string" ]
        then
            Non-empty string is not empty # 不，我们看不到这个
        else
            Non-empty string should not be empty but we reverse its result
        fi
    }
    test-if-string-is-empty-assert() {
        It keeps the original behavior by default

        Non-empty string should not be empty but we reverse its result
    }

    # 模拟测试命令 `[ ... ]` 是很有用的，比如当我们想去检查一个有绝对路径的文件是否存在的时候
    test-a-file-exists() {
        @mocktrue [ -f /etc/an-awesome-config.conf ]
        if [ -f /etc/an-awesome-config.conf ]; then
            Found this awesome config file
        else
            Even though this config file does not exist
        fi
    }
    test-a-file-exists-assert() {
        Found this awesome config file
    }

### 配置 Bach

有一系列的以 `BACH_` 开头的环境变量用于配置 Bach 测试框架，有

- `BACH_DEBUG`
  默认为 `false`，如果为 `true` 就会启用 Bach 的 `@debug` API
- `BACH_COLOR`
  默认为 `auto`，会根据使用情况来决定是否启用颜色输出；设置为 `always` 始终允许颜色输出；设置为 `no` 则不允许颜色输出。
- `BACH_TESTS`
  默认为空，表示执行所有测试。可以使用通配符来匹配之允许执行的测试用例。
- `BACH_DISABLED`
  默认为 `false`，如果为 `true` 则会禁用 Bach。如果希望把 Bach 直接集成到程序中，通过特定的开关来决定是否禁用 Bach。
- `BACH_ASSERT_DIFF`
  默认为系统中原始 PATH 环境变量中找到的第一个 `diff` 命令。用于比较测试执行方法和测试验证方法的执行结果时使用。
- `BACH_ASSERT_DIFF_OPTS`
  默认为 `-u`，用于 `$BACH_ASSERT_DIFF` 命令的选项。

## Bach 的限制

### 不能阻止直接使用绝对路径的命令调用

在这种场景下，直接命令的调用是由系统 API 直接完成，并不会与 Bash 发生任何交互，所以 Bach 无法拦截这样的命令。我们可以在 Bash 脚本中把这些绝对路径调用的命令，用一个方法来包装起来，然后再用 `@mock`/`@@mock` 等 API 来模拟这个方法。

### 在测试中禁止变更 PATH 环境变量

因为 Bach 要拦截所有的命令调用，而重设 `PATH` 会破坏 Bach 的行为，所以 Bach 中默认设置 PATH 环境变量为只读。

对于需要重设 PATH 的场景，建议使用 `declare` 内建命令来避免重设一个只读环境变量而导致的出错。

### 在 Bach 的以 `-assert` 结尾的测试验证方法中不可以模拟任何命令

因为 Bach 的测试验证就是通过分别执行测试执行函数和测试验证函数来达到的。我们已经在测试执行函数中模拟了命令的调用，在测试验证函数中，就应该直接写出期待执行的命令及其参数。在测试验证中模拟命令的调用是没有道理的。

### 在 Bach 中无法阻止 I/O 重定向

Bach 中被模拟的命令，已经支持了从标准输入读取命令和管道的调用。但对于使用 `>` `>>` 等等操作符的使用，解决办法一个是把重定向的命令用一个方法包装起来，另一个办法是在加载脚本的时候，用 `sed` 等命令把 `>` `>>` 等操作符用引号包含起来，把重定向的操作转换为普通的参数。

### 必须模拟管道中的每一个命令

在 Bash 中的管道命令事实上是运行在子进程中的，如果没有模拟这些命令，会导致管道命令的执行顺序并不一定是按照脚本中的调用顺序来执行的。为了确保 Bach 测试用例的执行稳定性，所有的管道命令必须按照其参数的使用来精确的模拟。

### 使用空集符号 `∅` 来表示空字符串

因为无法在终端上显示出空字符串, Bach 选择了用红色空集符号 `∅` 来指示这是一个空字符串。

当我们在测试报告中看到这个红色符号 `∅` 的时候，表示这个参数实际上是一个空字符串。

```
-foobar  ∅
+foobar
```

## Bach API 列表

Bach 测试框架中提供的 API 都是以 `@` 开头的。

### @assert-equals

断言两个值是否相等。

例子：

    @assert-equals "hello world" "HELLO WORLD"
    @assert-equals 1 2

### @assert-fail

断言前一个命令会执行失败

例子：

    false # 这个命令的返回值不为 0，则断言会成功
    @assert-fail

    true # 这个命令的返回值为 0，则断言会失败
    @assert-fail

### @assert-success

断言前一个命令要执行成功

例子：

    true # 这个命令的返回值为 0，则断言会成功
    @assert-fail

    false # 这个命令的返回值不为 0，则断言会失败
    @assert-fail

### @cd

执行真正的内置 `cd` 命令。

### @command

执行真正的内置 `command` 命令。

### @comment

这个命令用于在执行的结果中输出会被 Bach 忽略的注释，对于在失败的测试结果中定位问题很很有用。

### @debug

这个命令用于在执行测试的调试，如果执行测试的时候没有启用 `xtrace` 则这个命令不会有任何输出。

### @die

这个命令用于立刻终止并非正常退出，显示可选的错误消息

### @do-not-panic

为了尽可能的防止敲错这个 API，Bach 提供了以下的不同名称：

- `donotpanic`
- `dontpanic`
- `do-not-panic`
- `dont-panic`
- `do_not_panic`
- `dont_panic`

如果在 Bach 接管运行环境前执行了一个包含危险命令的测试，可能会带来很严重的后果。在包含危险命令的前面用上这个命令，会防止无意中调用这个危险的测试。

### @do-nothing

什么也不做。

通常在验证函数中只有这个 API 的时候来验证在测试汉中没有执行任何命令。

例如：

    test-nothing() {
        declare i=9
        if [[ "$i" -eq 0 ]]; then
            do-something
        fi
    }
    test-nothing-assert() {
        @do-nothing
    }

### @dryrun

在默认情况下，Bach 会使用 `@dryrun` 来确保任何命令都不会被运行。如果之前已经模拟了一个命令，但又不想真正运行，可以使用 `@dryrun` 来防止该命令被执行。

例子：

    @mock ls === @stdout file1 file2 # 做了了一个 `ls` 命令的模拟
    ls # 这个命令会返回 `file1` 和 `file2`
    @dryrun ls # 不运行 ls

### @echo

执行真正的内置 `echo` 命令。

### @err

显示一个错误消息

### @exec

执行真正的内置 `exec` 命令。

### @fail

立刻失败当前测试。

### @false

执行真正的内置 `false` 命令。

### @ignore

忽略被模拟的函数。

被忽略的函数，不会影响任何的测试和验证，且永远执行成功。

与 `@mocktrue` 不同的是，`@ignore` 忽略掉命令的任何参数。

例子：

    @ignore echo cd # 忽略掉 `echo` 和 `cd` 命令

### @load_function

加载指定脚本中的函数，用于测试一个脚本中的指定函数

例子：

    @load_function path/to/script.sh func-name # 加载脚本 path/to/script.sh 里面的 func-name 定义
    func-name foo bar # 加载成功后，就可以执行执行函数 `func-name` 了

### @mock

模拟命令或脚本的执行，如果命令执行的时候需要指定不同的参数，那就需要多次模拟。

注意：
- 如果要模拟一个脚本的执行，该脚本的路径必须是相对路径，不能模拟绝对路径的脚本。
- 多次模拟一个命令，只有最后一次的模拟生效

使用 `===` 来分割命令和输出

例子：

#### 模拟命令

    @mock ls file1 === @stdout file2

    ls file1 # 会在控制台输出 file2，列出文件 `file1`，但显示的是 `file2`，很怪，对不对？

    ls foo bar # 因为没有模拟 `ls` 命令和特定的参数，所以 `ls foo bar` 需要被验证

#### 模拟命令，但希望使用复杂的实现

例子：

    @mock ls <<<\CMD
      if [[ "$var" -eq 1 ]]; then
        @stdout one
      else
        @stdout others
      fi
    CMD


    var=1
    ls # 会输出 one，因为变量 `var` 的值是 `1`

    @unset var
    ls # 会输出 others，因为还没有定义变量 `var`

### @@mock

模拟命令的多次执行返回不同的值。

    test-ls() {
      @@mock ls === @stdout file1
      @@mock ls === @stdout file2
      @@mock ls === @stdout file3
      ls
      ls
      ls
      ls # 如果没有更多的命令序列，则会返回最后一次的模拟的结果
    }
    test-ls-assert() {
      @cat <<EOF
      file1
      file2
      file3
      file3
    EOF
    }

### @mockall

批量模拟多个命令，每个参数为一个命令。

例子：

    @mockall ls cd

### @mockfalse

模拟命令会执行失败

例子：

    @mockfalse ls

### @mocktrue

模拟命令会执行成功

例子：

    @mocktrue false

### @out

在标准输出终端上输出内容。

### @popd

执行真正的内置 `popd` 命令。

### @pushd

执行真正的内置 `popd` 命令。

### @pwd

执行真正的内置 `pwd` 命令。

### @real

执行真正的命令，将会执行在调用 Bach 时的 PATH 环境变量里面的命令。

### @run

用于在 Bach 的测试中执行被测试的脚本

### @setup

在测试的脚本中的每一个测试和测试断言函数之前都会被执行。

注意，由于在测试断言里面不允许模拟任何命令，所以在 `@setup` 里模拟的命令将会引起测试失败。

例子：

    @setup {
        @echo 在测试函数和测试断言函数中都会执行
    }

### @setup-assert

在测试的脚本中的每一个测试断言函数之前都会被执行。

注意，由于在测试断言里面不允许模拟任何命令，所以在 `@setup-assert` 里模拟的命令将会引起测试失败。

例子：

    @setup-assert {
        @echo 在测试断言函数中执行
    }

### @setup-test

在测试的脚本中的每一个测试函数之前都会被执行。

例子：

    @setup-tests {
        @echo 在测试函数中执行
    }

### @stderr

用于在错误控制台输出内容，每个参数输出一行。

### @stdout

用于在标准控制台输出内容，每个参数输出一行。

### @trap

执行真正的内置 `trap` 命令。

### @true

执行真正的内置 `true` 命令。

### @type

执行真正的内置 `type` 命令。

## 用 Bach 来学习 Bash 编程

我们可以用 Bach 来学习 Bash 编程，而不用担心有任何问题。

    test-learn-bash-no-double-quote-star() {
        @touch bar1 bar2 bar3 "bar*"

        function cleanup() {
            rm -rf $1
        }

        # 要删除这个错误的文件名 bar*，而不删除其他文件
        cleanup "bar*"
    }
    test-learn-bash-no-double-quote-star-assert() {
        # 但是在 cleanup 里面，遗漏了双引号，会导致变量被二次展开，将会删除所有文件
        rm -rf "bar*" bar1 bar2 bar3
    }

    test-learn-bash-double-quote-star() {
        @touch bar1 bar2 bar3 "bar*"

        function cleanup() {
            rm -rf "$1"
        }

        # 要删除这个错误的文件名 bar*，而不删除其他文件
        cleanup "bar*"
    }
    test-learn-bash-double-quote-star-assert() {
        # 在 cleanup 的实现里面有了双引号，将会正确的删除 `bar*` 这个文件。
        rm -rf "bar*"
    }

## Bach 的规划

* 开发一个 Bach 的命令行工具
* 在 Docker 容器内执行测试

## 正在使用 Bach 的客户

* 宝马集团(BMW Group)
* 华为(Huawei)

*按英文名称的字母顺序排序*

## 版本

Bach 当前最新的版本是 0.6.0，查看[Bach 的发布列表](https://github.com/bach-sh/bach/releases)

## 作者

* **Chai Feng** [github.com/chaifeng](https://github.com/chaifeng), [chaifeng.com](https://chaifeng.com)

## 版权

Bach 测试框架采用了双版权协议：

- [GNU General Public License v3.0](LICENSE.GPL-3.0)
- [Mzilla Public License 2.0](LICENSE.MPL-2.0)

请查看 [LICENSE](LICENSE)。
