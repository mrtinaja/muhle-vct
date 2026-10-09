<%@ Page Language="VB" AutoEventWireup="false" ValidateRequest="false" EnableViewStateMac="false" Inherits="MWebLibrary.clsWarningPage" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title>SofiaWeb</title>
</head>
<body style="text-align: center" onload="OnLoad();">
    <form id="frmWarningPage" runat="server">
    <div style="width: 100%; height: 100%; background-color: #ffffff">
    <table>
        <tr>
            <td colspan="2" class="it_headertexto_ma" style="height:50px;">Advertencia</td>
        </tr>
        <tr><td colspan="2"></td></tr>
        <tr>
            <td class="it_headertexto_us" style="background-color:#efefef;">Página:</td>
            <td class="it_headertexto_us" style="background-color:#efefef;"><%=GetPageName()%></td>
        </tr>
        <tr>
            <td class="it_headertexto_us" style="background-color:#efefef;">Mensaje:</td>
            <td class="it_headertexto_us" style="background-color:#efefef;"><%= GetWarningMessage()%></td>
        </tr>
        <tr><td colspan="2">&nbsp;</td></tr>
        <tr>
            <td>
                <a id="lnkOption" runat="server" class="ovalbutton"><span id="spanOption" runat="server" /></a>
            </td>
            <td>
                <div id="divExit" runat="server" style="display: none;">
                    <a id="lnkExit" class="ovalbutton" href="./SessionFinalizer.aspx"><span>Salir</span></a>
                </div>
            </td>
        </tr>
    </table>
    </div>
    </form>
</body>
</html>

