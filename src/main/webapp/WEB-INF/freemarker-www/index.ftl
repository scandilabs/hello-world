<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">

<head>
    <link type="text/css" rel="stylesheet" href="/css/global.css" media="screen, projection">
    
    <title>Hello World from ScandiLabs Java</title>
</head>
<body>
    <p>Hello world! <img src="/img/info-icon.png" /></p>
    
    <h3>Here is a list of users:</h3>
    <ul>
    <#list users as user>
        <li>${user.userName!"n/a"} (${user.email})</li>
    </#list>
    </ul>
    
    <p>Create <a href="/create-user">one more</a> right now!</p>
</body>
</html>