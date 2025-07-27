(function ($, window, document, undefined) {
    'use strict';

    $(document).ready(function () {
        window.location.href = "skp:ready@";
    }); //document.ready

    function ss() {
    }

    ss.remove_excess = function () {
        $("#tag-localparameter").empty();
    };

    ss.gen_time_step = function () {
        // language=Html
        var html =
            '<div class="h5 ">时间设置</div>' +
            '   <div id="time_setting">' +
            '   <div class=" pt-2" id = "setting_month">' +
            '          <div class="time_step">' +
            '              <span class="text">月</span>' +
            '              <select class="select time_step_month middle"  v-model="month" id="time_step_month_middle">' +
            '               <option v-for="month_item in 12">{{month_item}}</option>' +
            '              </select>' +
            '              <span class="sliders double">' +
            '                  <input class="slider time_step_month first middle" id="time_step_month_slider_middle" type="range" min=1' +
            '                  max=12 step=1 v-model="month" @input="onChangeTimeStepMonth(month)" @change="onChangeTimeStepMonth(month)"/>' +
            '              </span>' +
            '          </div>' +
            '   </div>' +
            '   <div class=" pt-2" id = "setting_day">' +
            '          <div class="time_step">' +
            '              <span class="text">日</span>' +
            '              <select class="select time_step_day middle"  v-model="day" id="time_step_day_middle">' +
            '               <option v-for="day_item in dayL">{{day_item}}</option>' +
            '              </select>' +
            '              <span class="sliders double">' +
            '                  <input class="slider time_step_day first middle" id="time_step_day_slider_middle" type="range" min=1' +
            '                  max=30 step=1 v-model="day" @input="onChangeTimeStepDay(day)" @change="onChangeTimeStepDay(day)"/>' +
            '              </span>' +
            '          </div>' +
            '   </div>' +
            '</div>';
        var $group = $(html);
        $("#time_step").append($group);

        var dayL = ss.createArray(31);

        ss.vm_time_setting = new Vue({
            el: '#time_setting',
            data: {
                month: 1,
                day: 1,
                hour: 1,
                dayL: dayL
            },
            methods: {
                onChangeTimeStepDay: function (day) {
                    this.day = day;
                    this.callback_time();
                },
                onChangeTimeStepMonth: function (month) {
                    this.month = month;
                    this.change_day_step(month);
                    this.callback_time();
                },
                selectTimeStateMonth: function (month) {
                    this.month = month;
                },
                selectTimeStateDay: function (day) {
                    this.day = day;
                },
                callback_time: function () {
                    window.location.href = "skp:callback_time@" + this.month + '|' + this.day;
                },
                change_day_step: function (month) {
                    var month = parseInt(month);
                    // Purpose: 【判断当前月份对应的日期总数】
                    let day31_month = [1, 3, 5, 7, 8, 10, 12];
                    var day_num = 30;
                    if ($.inArray(month, day31_month) > 0) {
                        day_num = 31
                    } else if (month === 2) {
                        day_num = 28
                    }
                    ;
                    // Purpose: 【记录当前day滑块位置的值】
                    if (this.day > day_num) this.day = day_num;
                    console.log("day_num= " + day_num);
                    this.dayL = ss.createArray(day_num);
                }
            }
        })
    };

    ss.createArray = function (count) {
        var arr = [];
        for (var i = 1; i <= count; i++) {
            arr.push(i);
        }
        return arr;
    };

    window.ss = ss;

    function sp() {
    }

    sp.initLibrary = function (info) {

        sp.cityLibrary = new Vue({
            el: '#tag-cityselector',
            data: {
                sorting: '0',
                grouping: '0',
                city: 'Guangzhou',
                index: '1',
                infos: [],
            },
            methods: {
                change_options: function (method, value) {
                    if (method === 'sorting') this.sorting = value;
                    else this.grouping = value;
                    this.view_list();
                    this.callback_json('save_sorting_n_grouping', {'sorting': this.sorting, 'grouping': this.grouping});
                },
                show_options: function (id) {
                    var el = document.getElementById(id + '_options');
                    el.style.display = 'block';
                    el.focus();
                },
                hide_options: function (id) {
                    var el = document.getElementById(id + '_options');
                    el.style.display = 'none';
                },
                submit_location: function (index) {
                    var info = this.infos[index];
                    this.callback_json("submit_location", info);
                },
                callback_json: function (name, data) {
                    var json = '';
                    if (data !== undefined) {
                        json = JSON.stringify(data);
                    }
                    window.location.href = "skp:callback_json@" + name + '|' + json;
                },
                select: function (el) {
                    sp.selected = el.getAttribute('data-id');
                    this.callback_json('select', {'id': sp.selected});
                    // outline();
                },
                filter_info: function () {
                    var str_filter = $("#filter").val();
                    var info_to_print;
                    if (str_filter === '') {
                        info_to_print = sp.cityLibrary.infos;//#.dup
                    } else {
                        info_to_print = [];
                        var filter_words = str_filter.split(' ');
                        $.each(sp.cityLibrary.infos, function (i_infos, info) {
                            var match = true;
                            $.each(filter_words, function (i_words, word) {
                                var word_match = false;
                                $.each(info, function (key_info, val_info) {
                                    if (typeof (val_info) == "string") {
                                        if (val_info.toLowerCase().indexOf(word.toLowerCase()) !== -1) word_match = true;
                                    } else if (typeof (val_info) == "number") {
                                        if (String(val_info).indexOf(String(word)) !== -1) word_match = true;
                                    }
                                });
                                if (!word_match) match = false;
                            });
                            if (match) info_to_print.push(info);
                        });

                    }
                    return info_to_print;
                },
                sort_info: function (info_to_print) {
                    if (this.sorting !== '0') {
                        //Sort (0 means don't sort, same as keeping the alphabetic order of titles).
                        info_to_print.sort(function (a, b) {
                            if (a[this.sorting] === '?') return 1;
                            if (a[this.sorting] === undefined) return 1;
                            if (b[this.sorting] === undefined) return -1;
                            if (a[this.sorting] === b[this.sorting]) {
                                return a['City'] < b['City'] ? -1 : 1;
                            }
                            return a[this.sorting] < b[this.sorting] ? -1 : 1;
                        });
                    }
                    return info_to_print;
                },
                view_list: function () {
                    var infos_to_print = this.filter_info();
                    infos_to_print = this.sort_info(infos_to_print);
                    //Group.
                    //Groups are associated arrays containing title (string) and content (array of template data).
                    var groups = [];
                    if (sp.cityLibrary.grouping == '0') {
                        //Put all in on group when grouping is 0.
                        groups.push({'title': 'City', 'content': infos_to_print});
                    } else {
                        // jquery的each，js需遍历
                        $.each(infos_to_print, function (index_infos, info) {
                            var group_by = info[sp.cityLibrary.grouping];
                            if (group_by === undefined) group_by = "Unknown";
                            var mathing_group = null;
                            $.each(groups, function (index_groups, group) {
                                if (group['title'] === group_by) mathing_group = group;
                            });
                            if (mathing_group) mathing_group['content'].push(info);
                            else groups.push({'title': group_by, 'content': [info]});
                        });
                        groups.sort(function (a, b) {
                            return a['title'] < b['title'] ? -1 : 1;
                        });
                    }

                    var html = '';
                    $.each(groups, function (i_grps, group) {
                        html += '<h4>' + group['title'] + '</h4>';
                        $.each(group['content'], function (i_infos, info) {
                            this.city = info.City;

                            this.index = info.ID;
                            // language=Html
                            html +=
                                '<span>' +
                                '   <button class="btn btn-sm btn-outline-dark" onclick="sp.cityLibrary.select_city(' + (this.ID - 1) + ')"> ' + this.City + ' </button>' +
                                '</span>';
                        });
                    });

                    $("#library").html($(html));
                },
                select_city: function (idx_info) {
                    var info = this.infos[idx_info];
                    vm_local.city = info.City;
                    vm_local.longitude = info.Longitude;
                    vm_local.latitude = info.Latitude;
                    this.submit_location(info.index);
                },
            }
        })

        $.each(info, function (i, e) {
            sp.cityLibrary.infos.push($.parseJSON(e));
        });
        sp.cityLibrary.view_list();
    };


    sp.createArray = function (count) {
        var arr = [];
        for (var i = 1; i <= count; i++) {
            arr.push(i);
        }
        return arr;
    };

    sp.gen_time_step = function () {
        // language=Html
        var html = `
            <div class="h5 ">Time Setting</div>
            <div id="time_setting">
                <div class=" pt-2" id="setting_month">
                    <div class="time_step">
                        <span class="text">Month:</span>
                        <select class="select time_step_month middle" v-model="month">
                            <option v-for="month_item in 12">{{month_item}}</option>
                        </select>
                        <span class="sliders double">
                  <input class="slider time_step_month first middle" type="range" min=1
                         max=12 step=1 v-model="month" @input="onChangeTimeStepMonth(month)"
                         @change="onChangeTimeStepMonth(month)"/>
              </span>
                    </div>
                </div>
                <div class=" pt-2" id="setting_day">
                    <div class="time_step">
                        <span class="text">Day:</span>
                        <select class="select time_step_day middle" v-model="day">
                            <option v-for="day_item in dayL">{{day_item}}</option>
                        </select>
                        <span class="sliders double">
                  <input class="slider time_step_day first middle" type="range" min=1
                         max=30 step=1 v-model="day" @input="onChangeTimeStepDay(day)"
                         @change="onChangeTimeStepDay(day)"/>
              </span>
                    </div>
                </div>
                <div class=" pt-2" id="setting_hour">
                    <div class="time_step">
                        <span class="text">Hour:</span>
                        <select class="select time_step_hour middle" v-model="hour">
                            <option v-for="hour_item in 24">{{hour_item}}</option>
                        </select>
                        <span class="sliders double">
                  <input class="slider time_step_hour first middle" type="range" min=1
                         max=24 step=1 v-model="hour" @input="onChangeTimeStepHour(hour)"
                         @change="onChangeTimeStepHour(hour)"/>
              </span>
                    </div>
                </div>
            </div>`;

        var $group = $(html);
        $("#time_step").append($group);

        var dayL = sp.createArray(31);

        sp.vm_time_setting = new Vue({
            el: '#time_setting',
            data: {
                month: 1,
                day: 1,
                hour: 1,
                dayL: dayL
            },
            methods: {
                onChangeTimeStepDay: function (day) {
                    this.day = day;
                    this.callback_time();
                },
                onChangeTimeStepHour: function (hour) {
                    this.hour = hour;
                    this.callback_time();
                },
                onChangeTimeStepMonth: function (month) {
                    this.month = month;
                    this.change_day_step(month);
                    this.callback_time();
                },
                selectTimeStateMonth: function (month) {
                    this.month = month;
                },
                selectTimeStateDay: function (day) {
                    this.day = day;
                },
                selectTimeStateHour: function (hour) {
                    this.hour = hour;
                },
                callback_time: function () {
                    window.location.href = "skp:callback_time@" + this.month + '|' + this.day + '|' + this.hour;
                },
                change_day_step: function (month) {
                    var month = parseInt(month);
                    // Purpose: 【判断当前月份对应的日期总数】
                    let day31_month = [1, 3, 5, 7, 8, 10, 12];
                    var day_num = 30;
                    if ($.inArray(month, day31_month) > 0) {
                        day_num = 31
                    } else if (month === 2) {
                        day_num = 28
                    }
                    ;
                    // Purpose: 【记录当前day滑块位置的值】
                    if (this.day > day_num) this.day = day_num;
                    console.log("day_num= " + day_num);
                    this.dayL = sp.createArray(day_num);
                }
            }
        })
    };


    window.sp = sp;

})(jQuery, window, document);
