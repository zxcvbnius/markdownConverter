# markdownConverter
Simple markdown to html converter with `markdown-it` and `coffeescript` to generate [api documents](http://api.diuit.com/doc/en/guideline.html#).


# Install Dependencies

```shell
$ cd . && npm install
```

# Command Line Interface

```shell
$ npm run-script run {YOUR_INPUT}.md {YOUR_OUT}.html
```

# Clean

```shell
$ npm run-script clean
```


# markdownConverter
Simple markdown to html converter with `markdown-it` and `coffeescript` to generate [api documents](http://api.diuit.com/doc/en/guideline.html#).


# Getting Started

## Prerequisites

You have to install [NPM](https://github.com/nodejs-tw/nodejs-wiki-book/blob/master/zh-tw/node_npm.rst) and [COFFEESCRIPT](http://coffeescript.org/) first


## Command Line

## convert

```shell
$ npm run-script convert {YOUR_INPUT}.md {YOUR_OUT}.html
```


# Example

There are several examples for you

## Tables

Diuit uses conventional HTTP response codes to indicate the success or failure of an API request. In the following we list a table of error codes we’ll return on our platform:


| Tables        | Price         | Count  |
| ------------- |:-------------:| ------:|
| col 1         |           $8  |     1  |
| col 2         |          $64  |     2  |
| col 3         |         $512  |    40  |


# Customize Note Example

```info
repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
```

```warning
repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
```

```success
repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
```

would generate

```
<div class="alert alert-info fade in">
  repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
</div>
```

```
<div class="alert alert-warning fade in">
  repositories { "maven { "url 'https://dl.bintray.com/duolc/maven' "} "}
</div>
```

# Coding Language Example

```java
Diuit.listChat()
```

```shell
$ echo 'Hello World'
```





# Install Dependencies

```shell
$ cd. && npm install
```

# Command Line Interface

```shell
$ npm run-script run {YOUR_INPUT}.md {YOUR_OUT}.html
```

# Clean

```shell
$ npm run-script clean
```
