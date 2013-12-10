<#import "spring.ftl" as spring />
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd" >
<html xmlns="http://www.w3.org/1999/xhtml">
<#assign page = "notFound">
<head>
</head>
<#flush>
<body>
	<h1>Sorry, but there has been some sort of error.</h1>				
	<#if logExceptionMessage??>
		<h3>${logExceptionMessage}</h3>
	</#if>			
	<p>If you receive this error message a second time, please <a href="mailto:support@example.com?subject=Site error, code: ${logExceptionID}">email us</a>.</p>
    <#if logException??>
        <h3>Stack trace:</h3>
        <p>${logException}</p>
    </#if>          
</body>
</html>