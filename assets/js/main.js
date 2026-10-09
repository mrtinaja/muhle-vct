/* =========================================================================
   MAIN.JS - MÜHLE PLATFORM / VOCATURO & ASOCIADOS
   Soporte operativo para transiciones asincrónicas y flujos de procesos.
   ========================================================================= */

function startSingleton(pContactKey, params, pTaskCode, pTaskDesc) {
    $('#mainContainer').hide();
    $('#loader').show();
    
    $.ajax({
        type: 'GET',
        url: '../task/Default.aspx',
        data: 'action_name=startsingleton&jobTypeCode=' + pTaskCode + '&custPkey=' + pContactKey + '&start_params=' + encodeURI(params),
        dataType: "text",
        success: function (data) {
            $("#mainContainer").html(data);
            $('#loader').hide();
            $("#mainContainer").show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function newTaskForContact(pContactKey, pTaskCode, pTaskDesc) {
    $('#mainContainer').hide();
    $('#loader').show();
    
    $.ajax({
        type: 'GET',
        url: '../task/Default.aspx',
        data: 'action_name=startactivity&jobTypeCode=' + pTaskCode + '&custPkey=' + pContactKey,
        dataType: "text",
        success: function (data) {
            $("#mainContainer").html(data);
            $('#loader').hide();
            $('#mainContainer').show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function newTaskForContactWithParams(pContactKey, params, pTaskCode, pTaskDesc) {
    $('#mainContainer').hide();
    $('#loader').show();

    $.ajax({
        type: 'GET',
        url: '../task/Default.aspx',
        data: 'action_name=startactivity&jobTypeCode=' + pTaskCode + '&custPkey=' + pContactKey + '&start_params=' + encodeURI(params),
        dataType: "text",
        success: function (data) {
            $("#mainContainer").html(data);
            $('#loader').hide();
            $('#mainContainer').show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function newTaskForContactWithParent(pContactKey, pTaskCode, pJobOrigin, div, loader) {
    $('#' + div).hide();
    $('#' + loader).show();

    $.ajax({
        type: 'GET',
        url: '../task/Default.aspx',
        data: 'action_name=startactivity & jobTypeCode=' + pTaskCode + '& custPkey=' + pContactKey + '& jobOriginPkey=' + pJobOrigin,
        dataType: "text",
        success: function (data) {
            $("#" + div).html(data);
            $('#' + loader).hide();
            $('#' + div).show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function restartTask(TaskPkey, ActivityPkey, TaskNumber, ParentPkey) {
    $('#mainContainer').hide();
    $('#loader').show();

    $.ajax({
        type: 'GET',
        url: '../task/Default.aspx',
        data: 'action_name=restartactivity&jobPkey=' + TaskPkey + '&attPkey=' + ActivityPkey + '&jobOriginPkey=' + ParentPkey,
        dataType: "text",
        success: function (data) {
            $("#mainContainer").html(data);
            $('#loader').hide();
            $('#mainContainer').show();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function openConfig() {
    // Implementación reservada para módulo de configuraciones del core
}

/* =========================================================================
   CONTROLADORES DE FLUJO Y ACCIONES DE BOTONES
   ========================================================================= */

function next(pStepKey) {
    $('#' + pStepKey + '_action_name').val("continue");
    sendForm(pStepKey);
}

function goto(pStepKey, psResultCode) {
    $('#' + pStepKey + '_action_name').val("salto");
    $('#' + pStepKey + '_ResultCode').val(psResultCode);
    sendForm(pStepKey);
}

function pending(pStepKey) {
    var wTodojobkey = '#' + pStepKey + "_todojobkey";
    var wAttkey = '#' + pStepKey + "_attkey";
    var wPhykey = '#' + pStepKey + "_phykey";
    var wGroupId = '#' + pStepKey + "_group";

    var query = {
        todojobkey: $(wTodojobkey).val(),
        attkey: $(wAttkey).val(),
        phykey: $(wPhykey).val(),
        group: $(wGroupId).val(),
        resultCode: '',
        schedule: false,
        sendTo: false
    };

    $('#mainContainer').hide();
    $('#loader').show();
    
    $.ajax({
        type: 'POST',
        url: '../task/ScheduleTask.ashx',
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            $('#loader').hide();
            $('#mainContainer').show();
            loadHome();
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function sendForm(pIdForm) {
    var form = $('#' + pIdForm);
    $('#mainContainer').hide();
    $('#loader').show();
    
    $.ajax({
        type: 'POST',
        url: '../task/Default.aspx',
        data: form.serialize(),
        dataType: "text",
        success: function (data) {
            if (data.indexOf('Finalize') > -1) {
                alert('Finalize');
            } else {
                $("#mainContainer").html(data);
                $('#loader').hide();
                $('#mainContainer').show();
            }
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

/* =========================================================================
   CONSTRUCTORES DINÁMICOS POR AJAX (CONTROLES SP / COMBOS ANIDADOS)
   ========================================================================= */

function BuildAjaxCombo(fieldType, fieldCode, ctlName, parentComboId, comboId, pStepKey) {
    document.getElementById(comboId).outerHTML = '<div id="' + comboId + '" class="fa fa-spinner w3-spin"></div>';
    
    var parentCombo = $('#' + parentComboId);
    var parentCatDataCode = parentCombo.val();
    var wTodojobkey = '#' + pStepKey + "_todojobkey";
    var wAttkey = '#' + pStepKey + "_attkey";
    var wPhykey = '#' + pStepKey + "_phykey";
    var wLastcnv = '#' + pStepKey + "_lastcnv";
    var wLaststep = '#' + pStepKey + "_laststep";
    var wPhystepkey = '#' + pStepKey + "_phystepkey";
    var uri = '../task/BuildAjaxControl.ashx';
    
    var query = {
        todojobkey: $(wTodojobkey).val(),
        attkey: $(wAttkey).val(),
        phykey: $(wPhykey).val(),
        phystepkey: $(wPhystepkey).val(),
        lastcnv: $(wLastcnv).val(),
        laststep: $(wLaststep).val(),
        fieldType: fieldType,
        fieldCode: fieldCode,
        ctlName: ctlName,
        parentCatDataCode: parentCatDataCode
    };

    $.ajax({
        type: 'GET',
        url: uri,
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            document.getElementById(comboId).outerHTML = data;
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function BuildAjaxSPComboWithCode(pStepKey, comboId, catpkey, selectedCode, parentCatDataCode) {
    $("#" + comboId).html('<div class="fa fa-spinner w3-spin"></div>');

    var wTodojobkey = '#' + pStepKey + "_todojobkey";
    var wAttkey = '#' + pStepKey + "_attkey";
    var wPhykey = '#' + pStepKey + "_phykey";
    var wLastcnv = '#' + pStepKey + "_lastcnv";
    var wLaststep = '#' + pStepKey + "_laststep";
    var wPhystepkey = '#' + pStepKey + "_phystepkey";
    var uri = '../task/BuildAjaxControlSP.ashx';
    
    var query = {
        todojobkey: $(wTodojobkey).val(),
        attkey: $(wAttkey).val(),
        phykey: $(wPhykey).val(),
        phystepkey: $(wPhystepkey).val(),
        lastcnv: $(wLastcnv).val(),
        laststep: $(wLaststep).val(),
        catpkey: catpkey,
        selectedCode: selectedCode,
        parentcatdatacode: parentCatDataCode
    };

    $.ajax({
        type: 'GET',
        url: uri,
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            $("#" + comboId).html(data);
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function BuildAjaxSPCombo(pStepKey, comboId, catpkey, selectedCode, parentComboId) {
    $("#" + comboId).html('<div class="fa fa-spinner w3-spin"></div>');

    var parentCatDataCode = '';
    if (parentComboId != '') {
        var parentCombo = $('#' + parentComboId);
        parentCatDataCode = parentCombo.val();
        if (parentCatDataCode == '') {
            parentCatDataCode = '{empty}';
        }
    }
    
    var wTodojobkey = '#' + pStepKey + "_todojobkey";
    var wAttkey = '#' + pStepKey + "_attkey";
    var wPhykey = '#' + pStepKey + "_phykey";
    var wLastcnv = '#' + pStepKey + "_lastcnv";
    var wLaststep = '#' + pStepKey + "_laststep";
    var wPhystepkey = '#' + pStepKey + "_phystepkey";
    var uri = '../task/BuildAjaxControlSP.ashx';
    
    var query = {
        todojobkey: $(wTodojobkey).val(),
        attkey: $(wAttkey).val(),
        phykey: $(wPhykey).val(),
        phystepkey: $(wPhystepkey).val(),
        lastcnv: $(wLastcnv).val(),
        laststep: $(wLaststep).val(),
        catpkey: catpkey,
        selectedCode: selectedCode,
        parentcatdatacode: parentCatDataCode
    };

    $.ajax({
        type: 'GET',
        url: uri,
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            $("#" + comboId).html(data);
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

function BuildAjaxSPTable(pTableId, pSPName, pStepKey) {
    document.getElementById(pTableId).outerHTML = '<div id="' + pTableId + '" class="fa fa-spinner w3-spin"></div>';

    var wTodojobkey = '#' + pStepKey + "_todojobkey";
    var wAttkey = '#' + pStepKey + "_attkey";
    var wPhykey = '#' + pStepKey + "_phykey";
    var wLastcnv = '#' + pStepKey + "_lastcnv";
    var wLaststep = '#' + pStepKey + "_laststep";
    var wPhystepkey = '#' + pStepKey + "_phystepkey";
    var uri = '../task/BuildAjaxSPTable.ashx';

    var query = {
        todojobkey: $(wTodojobkey).val(),
        attkey: $(wAttkey).val(),
        phykey: $(wPhykey).val(),
        phystepkey: $(wPhystepkey).val(),
        lastcnv: $(wLastcnv).val(),
        laststep: $(wLaststep).val(),
        tableId: pTableId,
        spName: pSPName
    };

    $.ajax({
        type: 'GET',
        url: uri,
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            document.getElementById(pTableId).outerHTML = data;
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

/* =========================================================
   GESTIÓN DE ARCHIVOS ADJUNTOS Y COMPONENTES DATATABLES
   ========================================================= */

function OpenAttach(pkey, filename) {
    window.open('../task/DownloadFile.ashx?action=view&pKey=' + pkey + '&fileName=' + filename, 'Adjunto', 'toolbar=no,menubar=no,scrollbars=yes,resizable=yes,width=800,height=600,top=10,left=10');
}

function DeleteAttach(pkey) {
    window.open('../task/DownloadFile.ashx?action=view&pKey=' + pkey + '&fileName=' + filename, 'Adjunto', 'toolbar=no,menubar=no,scrollbars=yes,resizable=yes,width=800,height=600,top=10,left=10');
}

function initDataTables() {
    $('.datatable').DataTable({
        aaSorting: [],
        responsive: true,
        searching: true,
        dom: 'Bfrtip',
        pageLength: 25,
        lengthMenu: [
            [10, 25, 50, -1],
            ['10 registros', '25 registros', '50 registros', 'Mostrar todos']
        ],
        buttons: [
            'pageLength',
            {
                extend: 'excelHtml5',
                title: 'report_export_excel'
            }
        ],
        language: {
            processing: "Procesando...",
            lengthMenu: "Mostrar _MENU_ registros",
            search: "Buscar:",
            info: "Mostrando registros del _START_ al _END_ de un total de _TOTAL_ registros",
            infoEmpty: "Mostrando registros del 0 al 0 de un total de 0 registros",
            infoFiltered: "(filtrado de un total de _MAX_ registros)",
            infoPostFix: "",
            InfoThousands: "",
            loadingRecords: "Cargando...",
            zeroRecords: "No se encontraron resultados",
            emptyTable: "Ningún dato disponible en esta tabla",
            buttons: {
                pageLength: 'Mostrar %d registros'
            },
            paginate: {
                first: "Primero",
                previous: "Anterior",
                next: "Siguiente",
                last: "Último"
            },
            aria: {
                sortAscending: ": Activar para ordenar la columna de manera ascendente",
                sortDescending: ": Activar para ordenar la columna de manera descendente"
            }
        }
    });
}

function initAttachFiles(pFileUploadId, pParKey) {
    var url = "../task/UploadFile.ashx";
    loadAttachFiles(pFileUploadId, pParKey);

    $('#' + pFileUploadId + '_fileupload').fileupload({
        url: url,
        dataType: 'text',
        start: function (e) {
            console.log('Uploads begin');
            $('#progressdiv').show();
        },
        progressall: function (e, data) {
            var progress = parseInt(data.loaded / data.total * 100, 10);
            $('#progressbar').css('width', progress + '%');
            $('#progressbar').innerHTML = progress + '%';
        },
        done: function (e, data) {
            console.log('Upload finished.');
        },
        stop: function (e) {
            console.log('Uploads finished');
            $('#progressdiv').hide();
            loadAttachFiles(pFileUploadId, pParKey);
        }
    });

    $('#' + pFileUploadId + '_fileupload').bind('fileuploadsubmit', function (e, data) {
        data.formData = { parkey : pParKey };
    });
}

function loadAttachFiles(pFileUploadId, pParKey) {
    var divAttachedFiles = '#' + pFileUploadId + "_attached_files";
    $(divAttachedFiles).html('<span><i class="fa fa-spinner w3-spin"></i> Cargando...</span>');

    var uri = '../task/AttachedFiles.ashx';
    var query = { parentPkey: pParKey };

    $.ajax({
        type: 'GET',
        url: uri,
        data: $.param(query),
        dataType: "text",
        success: function (data) {
            $(divAttachedFiles).html(data);
        },
        error: function (httpReq, status, exception) {
            console.log(status + " " + exception);
        }
    });
}

/* =========================================================
   FILTROS DE FORMULARIOS, COHESIÓN Y UTILIDADES GENERALES
   ========================================================= */

function saveCheckBoxValue(checkBox, hiddenFieldName) {
    var hiddenField = document.getElementsByName(hiddenFieldName)[0];
    if (checkBox.checked) {
        hiddenField.value = '1';
    } else {
        hiddenField.value = '0';
    }
}

function filterTable(idInput, idTable) {
    var input, filter, table, tr, td, i;
    input = document.getElementById(idInput);
    filter = input.value.toUpperCase();
    table = document.getElementById(idTable);
    tr = table.getElementsByTagName("tr");
    for (i = 0; i < tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[0];
        if (td) {
            txtValue = td.textContent || td.innerText;
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = "";
            } else {
                tr[i].style.display = "none";
            }
        }
    }
}

function filterList(idInput, idList) {
    var input, filter, ul, li, i;
    input = document.getElementById(idInput);
    filter = input.value.toUpperCase();
    ul = document.getElementById(idList);
    li = ul.getElementsByTagName("li");
    for (i = 0; i < li.length; i++) {
        txtValue = li[i].textContent || li[i].innerText;
        if (txtValue.toUpperCase().indexOf(filter) > -1) {
            li[i].style.display = "";
        } else {
            li[i].style.display = "none";
        }
    }
}

function toggleHeader(id) {
    var x = document.getElementById(id);
    if (x.className.indexOf("w3-show") == -1) {
        x.className += " w3-show";
    } else {
        x.className = x.className.replace(" w3-show", "");
    }
}

function saveSelection(fieldName, value) {
    var input = $('[name*="CALL.' + fieldName + '"]')[0];
    if (input) {
        input.value = value;
    }
}

function almacenarSeleccion(fieldName, value) {
    saveSelection(fieldName, value);
}