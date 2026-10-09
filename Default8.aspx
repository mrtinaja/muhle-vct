<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsLogin" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Vocaturo & Asociados | Portal de Clientes</title>
    
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.15.3/css/all.css">
    <link rel="shortcut icon" href="./favicon.ico" type="image/x-icon">
    <link rel="icon" href="./favicon.ico" type="image/x-icon">
    
    <style>
        * { box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body, html { height: 100%; margin: 0; padding: 0; background-color: #0f172a; }

        .vct-login-wrapper {
            height: 100%; width: 100%; display: flex; align-items: center; justify-content: center;
            background: linear-gradient(rgba(15, 23, 42, 0.5), rgba(15, 23, 42, 0.5)), 
                        url("./img/login-general.jpeg") no-repeat center center;
            background-size: cover; position: relative; padding: 20px;
        }

        .vct-login-card {
            width: 100%; max-width: 400px; background: rgba(30, 41, 59, 0.75) !important;
            backdrop-filter: blur(16px) saturate(120%); -webkit-backdrop-filter: blur(16px) saturate(120%);
            border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 20px; padding: 44px 32px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.4); text-align: center;
        }

        .vct-logo-container { width: 100%; padding: 0 10px; margin-bottom: 28px; display: flex; justify-content: center; }
        .vct-logo-container img { width: 100%; max-width: 220px; height: auto; object-fit: contain; display: block; mix-blend-mode: screen; opacity: 0.95; }

        .vct-login-card h1 { font-size: 20px; font-weight: 600; color: #ffffff; margin: 0 0 6px 0; letter-spacing: -0.02em; }
        .vct-login-card p.vct-subtitle { font-size: 13px; color: #94a3b8; margin: 0 0 32px 0; }
        .vct-input-group { margin-bottom: 22px; text-align: left; }
        .vct-input-group label { display: block; font-size: 11px; font-weight: 600; color: #cbd5e1; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 6px; }
        .vct-input-wrapper { position: relative; display: flex; align-items: center; }
        .vct-input-wrapper i { position: absolute; left: 14px; color: #94a3b8; font-size: 14px; pointer-events: none; }

        .vct-input-wrapper input {
            width: 100%; height: 44px !important; padding: 0 14px 0 42px !important;
            border: 1px solid rgba(255, 255, 255, 0.15) !important; border-radius: 10px !important;
            background: rgba(15, 23, 42, 0.4) !important; color: #ffffff !important; font-size: 14px !important;
            outline: none !important; transition: all 0.2s ease !important;
        }
        .vct-input-wrapper input::placeholder { color: #475569; }
        .vct-input-wrapper input:focus { background: rgba(15, 23, 42, 0.6) !important; border-color: #ffffff !important; }

        .vct-btn-login {
            width: 100%; height: 44px; background: #ffffff; border: none; border-radius: 10px;
            color: #0f172a; font-size: 14px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transition: all 0.2s ease; margin-top: 10px;
        }
        .vct-btn-login:hover { transform: translateY(-1px); background: #f1f5f9; }

        .isa_warning { margin: 16px 0 0 0; padding: 12px; border-radius: 10px; font-size: 12px; font-weight: 500; color: #fef08a; background-color: rgba(234, 179, 8, 0.15); border: 1px solid rgba(234, 179, 8, 0.3); text-align: left; }
        .vct-login-footer { margin-top: 32px; font-size: 11px; color: #64748b; border-top: 1px solid rgba(255, 255, 255, 0.1); padding-top: 16px; }
        .vct-login-footer a { color: #cbd5e1; text-decoration: none; }
    </style>
</head>
<body>

<div class="vct-login-wrapper">
    <div class="vct-login-card">
        <div class="vct-logo-container">
            <img src="./img/logo.jpg" alt="Vocaturo & Asociados">
        </div>
        <h1>Portal de Clientes</h1>
        <p class="vct-subtitle">Ingresa para gestionar tus servicios</p>

        <form runat="server" id="loginForm">
            <input type="hidden" name="module" value="USER"/>

            <div class="vct-input-group">
                <label for="txtUserId">Usuario</label>
                <div class="vct-input-wrapper">
                    <i class="fas fa-user"></i>
                    <input runat="server" type="text" name="txtUserId" id="txtUserId" placeholder="Ingresar Usuario" required autocomplete="username"/> 
                </div>
            </div>

            <div class="vct-input-group">
                <label for="txtPassword">Contraseña</label>
                <div class="vct-input-wrapper">
                    <i class="fas fa-lock"></i>
                    <input runat="server" type="password" name="txtPassword" id="txtPassword" placeholder="••••••••" required autocomplete="current-password"/>
                </div>
            </div>

            <button type="submit" class="vct-btn-login">
                Ingresar al Portal &nbsp;<i class="fas fa-arrow-right"></i>
            </button>
            <div class="isa_warning" id="result" style="display:none"></div>
            <div class="vct-login-footer">
                Powered by Mühle &nbsp;|&nbsp; <a href="https://squad.com.ar" target="_blank">Squad S.R.L.</a>
            </div>
        </form>
    </div>
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
                if (data == "OK"){
                    location.href = './main/';
                } else {
                    $("#result").show().html(data);
                }
            },
            error : function(httpReq, status, exception){
                console.log(status + " " + exception);
            }
        });
    });
</script>
</body>
</html>