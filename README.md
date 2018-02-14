# chat2

A simple telnet app to chat with a server.  It uses
`send` and `expect` to chat and wait for an expected response.
There is also an `exec` method to send and expect in sequence.

This module allows you to chat programatically to any server such as
a POP3 server or an SMTP server that uses a known protocol
that can be sent to and expected.  It uses native Promises
and is pipeline safe: you can send and expect from multiple async 
calls and the data will arrive back in the right order.

## Install

```
npm install chat2
```

## Example

```javascript

static Chat2 = require('chat2');

static chat = new Chat2('localhost', 110, 5000);
chat.connect()
.then(() => {
  chat.expect(/^\+OK/);
})
.then(() => {
  chat.send('USER cliff');
  chat.exec('PASS password', /^+OK/);
})
.then(response => {
  console.log(response);
  chat.send('QUIT');
  chat.close()
})
```
## Constructor

```javascript
const chat2 = new Chat2(host, port, timeout);
```

#### host

hostname or IP address

#### port

a numeric port, defaulting to 23 if not provided

####timeout 

a timeout in milliseconds, defaulting to no timeout

## Methods

### connect

```javascript
chat2.connect();
```

This sets up the connection to the server, sets encoding
to utf-8 and sets a keepalive.  It mus be called before any other
methods.

### expect

```javascript
chat2.expect(<pattern>)
.then(line => {
  console.log("Received: " + line);
});
```

Called with a regular expression, it returns a promise.  The promise resolves
when the regular expression is matched, returning the full line that
matched.

### send

```javascript
chat2.send(<message>)
.then(() => {
});
```

Sends a message to the server, returning a promise.  The promise
resolves with the message sent.

### exec

```javascript
chat2.exec(<message>, <pattern>)
.then(line => {
  console.log("Received: " + line);
});
```

This calls `send` followed by `expect`.  It returns a promise
which is resolved to the first line that matches the pattern.

Both `expect` and `exec` will reject the promise if the timeout
is reached.  The caught error will be of type `ETIMEDOUT`.

### close

```javascript
chat2.close()
```

This will close the connection cleanly and leave the chat2 instance
ready to be reconnected, if desired.

## History

This program is called chat2 as it was inspired by
Randal L. Schwartz' Perl 4 program [chat2.pl](http://chat2.pl)
from 1991.

## Similar programs

The [teletype](https://www.npmjs.com/package/teletype) module
is similar but will lose data if it comes in too fast.


## Issues

Please let me know of any issues at the
[Github Issues page](https://github.com/CliffS/chat2/issues).
