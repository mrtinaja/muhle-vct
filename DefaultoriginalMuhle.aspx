<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsLogin" %>
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mülhe | Log in</title>
<link rel="shortcut icon" href="./favicon.ico" type="image/x-icon">
<link rel="icon" href="./favicon.ico" type="image/x-icon">
<style>
body, html {
  height: 100%;
  margin: 0;
  font-family: Arial, Helvetica, sans-serif;
}

* {
  box-sizing: border-box;
}

.bg-img {
  /* The image used */
  background-image: url("./img/back-login.jpg");
  height: 100%;

  /* Center and scale the image nicely */
  background-position: center;
  background-repeat: no-repeat;
  background-size: cover;
  position: relative;
}

/* Add styles to the form container */
.container {
  position: absolute;
  right: 0;
  margin: 80px;
  max-width: 300px;
  padding: 16px;
  background-color: white;
}

/* Full-width input fields */
input[type=text], input[type=password] {
  width: 100%;
  padding: 15px;
  margin: 5px 0 22px 0;
  border: none;
  background: #f1f1f1;
}

input[type=text]:focus, input[type=password]:focus {
  background-color: #ddd;
  outline: none;
}

/* Set a style for the submit button */
.btn {
  background-color: #4CAF50;
  color: white;
  padding: 16px 20px;
  border: none;
  cursor: pointer;
  width: 100%;
  opacity: 0.9;
}

.btn:hover {
  opacity: 1;
}

.isa_info, .isa_success, .isa_warning, .isa_error {
margin: 10px 0px;
padding:12px;
 
}
.isa_info {
    color: #00529B;
    background-color: #BDE5F8;
}
.isa_success {
    color: #4F8A10;
    background-color: #DFF2BF;
}
.isa_warning {
    color: #9F6000;
    background-color: #FEEFB3;
}
.isa_error {
    color: #D8000C;
    background-color: #FFD2D2;
}
.isa_info i, .isa_success i, .isa_warning i, .isa_error i {
    margin:10px 22px;
    font-size:2em;
    vertical-align:middle;
}

.imgcontainer {
  text-align: center;
  margin: 24px 0 12px 0;
}

</style>

</head>
<body>

<div class="bg-img">
  <form runat="server" id="loginForm" class="container">
	  <div class="imgcontainer">
		<img src="./img/logo_main.jpg" alt="Avatar" class="avatar">
	  </div>

    <label for="txtUserId"><b>Usuario</b></label>
    <input runat="server" type="text" name="txtUserId" id="txtUserId" placeholder="Ingresar Usuario" required/> 

    <label for="psw"><b>Contraseña</b></label>
    <input runat="server" type="password" name="txtPassword" id="txtPassword" placeholder="Ingresar Contraseña" required />
    
    <input type="hidden" name="module" value="USER"/>
    
      <button type="submit" class="btn">Login</button>
    <div class="isa_warning" id="result" style="display:none"></div>
    <p style="font-size:12px">Powered by Mühle | <a href="https://squad.com.ar">Squad S.R.L.</a></p>
  </form>

</div>

<!-- jQuery 3 -->
<script src="./lib/jquery/jquery.min.js"></script>
<!-- iCheck -->
<script src="./lib/iCheck/icheck.min.js"></script>
<script>
  $(function () {
    $('input').iCheck({
      checkboxClass: 'icheckbox_square-blue',
      radioClass: 'iradio_square-blue',
      increaseArea: '20%' /* optional */
    });
  });

    $("#loginForm").submit(function(event){
	    // cancels the form submission
	    event.preventDefault();
	
	    $.ajax({ 
		    type: 'POST',
		    url: './login/',
		    data: $("#loginForm").serialize(),
		    dataType: "text",
		    success : function(data){
			    if (data == "OK"){
				    // Codigo en caso de exito
				    location.href = './main/';
                } else {
                    $("#result").show();
				    $("#result").html(data);
			    }

		    },
		    beforeSend: function() {
			    // This callback function will trigger before data is sent
		    },
		    complete: function() {
			    // This callback function will trigger after data is received
		    },
		    error : function(httpReq,status,exception){
			    console.log(status+" "+exception);
		    }
	    });
			
    });
</script>
</body>
</html>
