<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsLogin" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mühle | Vocaturo & Asociados – Sistema de Gestión</title>
<link rel="shortcut icon" href="./favicon.ico" type="image/x-icon">
<link rel="icon" href="./favicon.ico" type="image/x-icon">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
body, html {
  height: 100%;
  margin: 0;
  font-family: 'Inter', Arial, Helvetica, sans-serif;
  background-color: #0f172a;
}
* { box-sizing: border-box; }

/* 🌅 FONDO GARANTIZADO EN PANTALLA COMPLETA */
.bg-img {
  background-image: url("./img/fondo_admin.jpeg") !important;
  min-height: 100vh;
  width: 100%;
  background-position: center;
  background-repeat: no-repeat;
  background-size: cover;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

/* 🌌 CONTENEDOR GLASSMORPHISM */
.container {
  border-radius: 24px;
  width: 100%;
  max-width: 420px;
  overflow: hidden; 
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5), inset 0 0 0 1px rgba(255, 255, 255, 0.15) !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
  padding: 0 !important; 
  background: rgba(15, 23, 42, 0.45) !important;
  backdrop-filter: blur(20px) saturate(160%) !important;
  -webkit-backdrop-filter: blur(20px) saturate(160%) !important;
}

/* ⚪ HEADER BLANCO CON LOGO */
.vct-login-header {
  background: #ffffff !important;
  padding: 30px 40px 20px 40px;
  text-align: center;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}
.vct-login-header img {
  max-height: 50px;
  width: auto;
  margin-bottom: 12px;
  display: inline-block;
}

.vct-login-body {
  padding: 24px 40px 35px 40px;
}
.lbl-title-custom {
  font-weight: 800;
  color: #66062D; /* Bordó */
  letter-spacing: -0.04em;
  margin: 0 0 2px 0;
  font-size: 24px;
}
.lbl-subtitle-custom {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
  margin: 0;
}
label {
  color: rgba(255, 255, 255, 0.9);
  font-size: 13px;
  font-weight: 600;
  display: block;
  margin-top: 10px;
}
input[type=text], input[type=password] {
  width: 100%;
  height: 50px;
  padding: 15px;
  margin: 6px 0 16px 0;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  font-family: 'Inter', sans-serif;
  font-size: 14px;
  font-weight: 500;
  color: #ffffff;
  outline: none;
  transition: all 0.2s ease;
}
input[type=text]::placeholder, input[type=password]::placeholder {
  color: rgba(255, 255, 255, 0.4);
}
input[type=text]:focus, input[type=password]:focus {
  border-color: #ff4b91;
  background-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 0 0 4px rgba(255, 75, 145, 0.15);
}
.btn {
  background-color: #66062D;
  color: white;
  height: 50px;
  border-radius: 12px;
  border: none;
  cursor: pointer;
  width: 100%;
  font-weight: 600;
  font-size: 15px;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(102, 6, 45, 0.3);
  margin-top: 12px;
}
.btn:hover {
  background-color: #7B0C3A;
  transform: translateY(-1px);
}
.isa_warning {
  margin: 15px 0px;
  padding: 12px;
  color: #D8000C;
  background-color: #FFD2D2;
  border-radius: 12px;
  font-size: 13px;
  text-align: center;
}
</style>
</head>
<body>
<div class="bg-img">
  <form runat="server" id="loginForm" class="container">
    <div class="vct-login-header">
        <img src="./img/logo.jpg" alt="Vocaturo & Asociados">
        <h3 class="lbl-title-custom">Sistema de Gestión</h3>
        <p class="lbl-subtitle-custom">Ingresá tus credenciales</p>
    </div>
    <div class="vct-login-body">
        <label for="txtUserId">Usuario</label>
        <input runat="server" type="text" name="txtUserId" id="txtUserId" placeholder="Usuario" required autocomplete="username"/> 
        
        <label for="txtPassword">Contraseña</label>
        <input runat="server" type="password" name="txtPassword" id="txtPassword" placeholder="Contraseña" required autocomplete="current-password"/>
        
        <input type="hidden" name="module" value="USER"/>
        <button type="submit" class="btn">Ingresar</button>
        <div class="isa_warning" id="result" style="display:none"></div>
        
        <p style="font-size:11px; text-align:center; color:rgba(255,255,255,0.6); margin-top:25px; font-weight: 500;">
            Powered by Mühle V4 - 2026 | <a href="https://squad.com.ar" style="color:#ff4b91; font-weight:700; text-decoration:none;" target="_blank">Squad S.R.L.</a>
        </p>
    </div>
  </form>
</div>
<script src="./lib/jquery/jquery.min.js"></script>
<script>
    $("#loginForm").submit(function(event){
        event.preventDefault();
        $.ajax({ 
            type: 'POST',
            url: './login/',
            data: $("#loginForm").serialize(),
            dataType: "text",
            success : function(data){
                if (data == "OK"){ location.href = './main/'; } 
                else { $("#result").show().html(data); }
            },
            error : function(httpReq,status,exception){ console.log(status+" "+exception); }
        });
    });
</script>
</body>
</html>