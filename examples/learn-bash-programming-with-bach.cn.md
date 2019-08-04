#!/usr/bin/env bash
# 用 Bach 来学习 Bash 编程

## 利用 Shell Common Functions Library 导入 Bach 测试框架

    declare -grx self="$(realpath "${BASH_SOURCE}")"
    source <("${self%/*/*}"/cflib-import.sh)
    require bach

## 为什么双引号很重要

### 没有双引号会导致变量被二次展开

    test-学习-Bash-编程之-没有双引号() {
    
#### 这里有个函数，把接受到的参数传递给 no-double-quote 命令，但是没有用双引号把 $@ 包含起来

        function foo() {
            no-double-quote $@
        }
        
#### 调用这个函数，传递了一个参数，是字符串『a b c d』

        foo "a b c d"
    }
    
#### 但是命令 'no-double-quote' 却接受到了『四』个参数！分别是 『a』、『b』、『c』、『d』
    
    test-学习-Bash-编程之-没有双引号-assert() {
        no-double-quote a b c d
    }

### 通常在 Bash 编程中，变量都应该使用双引号，除非你明确的知道你在做什么

    test-学习-Bash-编程之-使用双引号() {
    
#### 这里有个函数，把接受到的参数传递给 double-quotes，并且使用了双引号把 $@ 包含了起来

        function foo() {
            double-quotes "$@"
        }
        
#### 调用这个函数，传递了一个参数，是字符串『a b c d』

        foo "a b c d"
    }
    
#### 命令 'double-quotes' 接受到了这个正确的参数，就一个参数『a b c d』

    test-学习-Bash-编程之-使用双引号-assert() {
        double-quotes "a b c d"
    }

### 忘记双引号可能会导致严重后果

    test-学习-Bash-编程之-忘记双引号可能会导致严重后果() {
    
#### 假设我们有四个文件，分别是 bar1、bar2、bar3 和 bar*

        @touch bar1 bar2 bar3 "bar*"

#### 我们有一个函数用来删除文件，但是里面没有使用双引号把 $1 包含起来

        function cleanup() {
            rm -rf $1
        }
        
#### 我们使用这个自定义的函数来删除文件 『bar*』,而不是其他三个文件

        cleanup "bar*"
    }
    test-学习-Bash-编程之-忘记双引号可能会导致严重后果-assert() {
    
#### 因为没有双引号，导致这个星号在函数内部展开，将会删除所有的文件

        rm -rf "bar*" bar1 bar2 bar3
    }

### 双引号对于Bash的变量很重要

    test-学习-Bash-编程之-双引号对于Bash的变量很重要() {

#### 假设我们有四个文件，分别是 bar1、bar2、bar3 和 bar*

        @touch bar1 bar2 bar3 "bar*"

#### 我们有一个函数用来删除文件，而且也正确的使用双引号把 $1 包含起来了

        function cleanup() {
            rm -rf "$1"
        }
        
#### 我们使用这个自定义的函数来删除文件 『bar*』,而不是其他三个文件

        cleanup "bar*"
    }
    test-学习-Bash-编程之-双引号对于Bash的变量很重要-assert() {

#### 因为使用了双引号，这个星号没有在函数内部展开，所以只删除了文件『bar*』

        rm -rf "bar*"
    }
