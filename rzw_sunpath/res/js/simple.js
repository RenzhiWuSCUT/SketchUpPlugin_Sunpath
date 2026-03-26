$(document).ready(function () {
    window.location.href = "skp:ready@";
});

function col_info(info) {
    $("#header").html(info);
}


function gen_script_make_mask() {
    var html =
        '<script type="text/javascript" src="../js/make_mask.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_mrt_calculator() {
    var html =
        '<script type="text/javascript" src="../js/mrt_calculator.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_cmrt_post() {
    var html =
        '<script type="text/javascript" src="../js/cmrt_post.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_cmrt_clbm_post() {
    var html =
        '<script type="text/javascript" src="../js/clbm_cmrt_post.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};


function gen_script_clbm_post() {
    var html =
        '<script type="text/javascript" src="../js/clbm_post.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_clbm_calculator() {
    var html =
        '<script type="text/javascript" src="../js/clbm.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_clbm_cmrt_calculator() {
    var html =
        '<script type="text/javascript" src="../js/clbm_cmrt.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_tout_post() {
    var html =
        '<script type="text/javascript" src="../js/tout_post.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};

function gen_script_epw_reader() {
    var html =
        '<script type="text/javascript" src="../js/epw_reader.js"></script>';
    var $group = $(html);
    $("#head").append($group);
};
