(function ($, window, document, undefined) {
    'use strict';

    function callRuby(methodName) {
        var args = Array.prototype.slice.call(arguments, 1);
        if (!window.sketchup || typeof window.sketchup[methodName] !== 'function') {
            throw new Error('SketchUp callback not available: ' + methodName);
        }
        window.sketchup[methodName].apply(window.sketchup, args);
    }

    function createArray(count) {
        var arr = [];
        for (var i = 1; i <= count; i++) {
            arr.push(i);
        }
        return arr;
    }

    function normalizeInfoArray(info) {
        var out = [];
        $.each(info || [], function (i, e) {
            if (typeof e === 'string') {
                out.push($.parseJSON(e));
            } else {
                out.push(e);
            }
        });
        return out;
    }

    function monthDayCount(month) {
        month = parseInt(month, 10);
        var day31_month = [1, 3, 5, 7, 8, 10, 12];
        if ($.inArray(month, day31_month) >= 0) {
            return 31;
        }
        if (month === 2) {
            return 28;
        }
        return 30;
    }

    function buildTimeSettingHTML(titleMonth, titleDay, titleHour) {
        return `
            <div class="h5">Time Setting</div>
            <div id="time_setting">
                <div class="pt-2" id="setting_month">
                    <div class="time_step">
                        <span class="text">${titleMonth}</span>
                        <select class="select time_step_month middle"
                                v-model.number="month"
                                id="time_step_month_middle">
                            <option v-for="month_item in 12" :key="'m' + month_item" :value="month_item">
                                {{month_item}}
                            </option>
                        </select>
                        <span class="sliders double">
                            <input class="slider time_step_month first middle"
                                   id="time_step_month_slider_middle"
                                   type="range"
                                   min="1"
                                   max="12"
                                   step="1"
                                   v-model.number="month"
                                   @input="onChangeTimeStepMonth(month)"
                                   @change="onChangeTimeStepMonth(month)"/>
                        </span>
                    </div>
                </div>

                <div class="pt-2" id="setting_day">
                    <div class="time_step">
                        <span class="text">${titleDay}</span>
                        <select class="select time_step_day middle"
                                v-model.number="day"
                                id="time_step_day_middle">
                            <option v-for="day_item in dayL" :key="'d' + day_item" :value="day_item">
                                {{day_item}}
                            </option>
                        </select>
                        <span class="sliders double">
                            <input class="slider time_step_day first middle"
                                   id="time_step_day_slider_middle"
                                   type="range"
                                   min="1"
                                   :max="dayL.length"
                                   step="1"
                                   v-model.number="day"
                                   @input="onChangeTimeStepDay(day)"
                                   @change="onChangeTimeStepDay(day)"/>
                        </span>
                    </div>
                </div>

                <div class="pt-2" id="setting_hour">
                    <div class="time_step">
                        <span class="text">${titleHour}</span>
                        <select class="select time_step_hour middle"
                                v-model.number="hour"
                                id="time_step_hour_middle">
                            <option v-for="hour_item in 24" :key="'h' + hour_item" :value="hour_item">
                                {{hour_item}}
                            </option>
                        </select>
                        <span class="sliders double">
                            <input class="slider time_step_hour first middle"
                                   id="time_step_hour_slider_middle"
                                   type="range"
                                   min="1"
                                   max="24"
                                   step="1"
                                   v-model.number="hour"
                                   @input="onChangeTimeStepHour(hour)"
                                   @change="onChangeTimeStepHour(hour)"/>
                        </span>
                    </div>
                </div>
            </div>
        `;
    }

    function mountTimeSetting(namespaceObj, labels) {
        $('#time_step').empty().append(buildTimeSettingHTML(labels.month, labels.day, labels.hour));

        namespaceObj.vm_time_setting = new Vue({
            el: '#time_setting',
            data: {
                month: 1,
                day: 1,
                hour: 1,
                dayL: createArray(31)
            },
            methods: {
                onChangeTimeStepMonth: function (month) {
                    this.month = Number(month);
                    this.change_day_step(this.month);
                    this.callback_time();
                },
                onChangeTimeStepDay: function (day) {
                    this.day = Number(day);
                    this.callback_time();
                },
                onChangeTimeStepHour: function (hour) {
                    this.hour = Number(hour);
                    this.callback_time();
                },
                selectTimeStateMonth: function (month) {
                    this.month = Number(month);
                    this.change_day_step(this.month);
                },
                selectTimeStateDay: function (day) {
                    this.day = Number(day);
                },
                selectTimeStateHour: function (hour) {
                    this.hour = Number(hour);
                },
                callback_time: function () {
                    callRuby('callback_time', this.month, this.day, this.hour);
                },
                change_day_step: function (month) {
                    var day_num = monthDayCount(month);
                    if (this.day > day_num) {
                        this.day = day_num;
                    }
                    this.dayL = createArray(day_num);
                }
            }
        });
    }

    function mountCityLibrary(namespaceObj, info) {
        if (namespaceObj.cityLibrary && namespaceObj.cityLibrary.$destroy) {
            namespaceObj.cityLibrary.$destroy();
        }

        namespaceObj.cityLibrary = new Vue({
            el: '#tag-cityselector',
            data: {
                sorting: '0',
                grouping: '0',
                city: 'Guangzhou',
                index: '1',
                infos: normalizeInfoArray(info)
            },
            methods: {
                change_options: function (method, value) {
                    if (method === 'sorting') {
                        this.sorting = value;
                    } else {
                        this.grouping = value;
                    }
                    this.view_list();
                },
                show_options: function (id) {
                    var el = document.getElementById(id + '_options');
                    if (el) {
                        el.style.display = 'block';
                        el.focus();
                    }
                },
                hide_options: function (id) {
                    var el = document.getElementById(id + '_options');
                    if (el) {
                        el.style.display = 'none';
                    }
                },
                submit_location: function (index) {
                    var info = this.infos[index];
                    callRuby('submit_location', JSON.stringify(info));
                },
                callback_json: function (name, data) {
                    if (name === 'submit_location') {
                        callRuby('submit_location', JSON.stringify(data));
                    } else {
                        throw new Error('Unsupported callback_json action: ' + name);
                    }
                },
                select: function (el) {
                    namespaceObj.selected = el.getAttribute('data-id');
                },
                filter_info: function () {
                    var str_filter = $('#filter').val();
                    var info_to_print;

                    if (str_filter === '') {
                        info_to_print = this.infos.slice();
                    } else {
                        info_to_print = [];
                        var filter_words = str_filter.split(' ');

                        $.each(this.infos, function (i_infos, info) {
                            var match = true;

                            $.each(filter_words, function (i_words, word) {
                                if (!word) {
                                    return;
                                }

                                var word_match = false;

                                $.each(info, function (key_info, val_info) {
                                    if (typeof val_info === 'string') {
                                        if (val_info.toLowerCase().indexOf(word.toLowerCase()) !== -1) {
                                            word_match = true;
                                        }
                                    } else if (typeof val_info === 'number') {
                                        if (String(val_info).indexOf(String(word)) !== -1) {
                                            word_match = true;
                                        }
                                    }
                                });

                                if (!word_match) {
                                    match = false;
                                }
                            });

                            if (match) {
                                info_to_print.push(info);
                            }
                        });
                    }

                    return info_to_print;
                },
                sort_info: function (info_to_print) {
                    var sortingKey = this.sorting;

                    if (sortingKey !== '0') {
                        info_to_print.sort(function (a, b) {
                            if (a[sortingKey] === '?') return 1;
                            if (a[sortingKey] === undefined) return 1;
                            if (b[sortingKey] === undefined) return -1;
                            if (a[sortingKey] === b[sortingKey]) {
                                return a.City < b.City ? -1 : 1;
                            }
                            return a[sortingKey] < b[sortingKey] ? -1 : 1;
                        });
                    }

                    return info_to_print;
                },
                view_list: function () {
                    var infos_to_print = this.filter_info();
                    infos_to_print = this.sort_info(infos_to_print);

                    var groups = [];
                    var self = this;

                    if (self.grouping === '0') {
                        groups.push({title: 'City', content: infos_to_print});
                    } else {
                        $.each(infos_to_print, function (index_infos, info) {
                            var group_by = info[self.grouping];
                            if (group_by === undefined) {
                                group_by = 'Unknown';
                            }

                            var matching_group = null;
                            $.each(groups, function (index_groups, group) {
                                if (group.title === group_by) {
                                    matching_group = group;
                                }
                            });

                            if (matching_group) {
                                matching_group.content.push(info);
                            } else {
                                groups.push({title: group_by, content: [info]});
                            }
                        });

                        groups.sort(function (a, b) {
                            return a.title < b.title ? -1 : 1;
                        });
                    }

                    var html = '';
                    $.each(groups, function (i_grps, group) {
                        html += '<h4>' + group.title + '</h4>';
                        $.each(group.content, function (i_infos, info) {
                            var idx = self.infos.indexOf(info);
                            html += '<span>' +
                                '<button class="btn btn-sm btn-outline-dark me-1 mb-1" onclick="sp.cityLibrary.select_city(' + idx + ')">' +
                                info.City +
                                '</button>' +
                                '</span>';
                        });
                    });

                    $('#library').html(html);
                },
                select_city: function (idx_info) {
                    var info = this.infos[idx_info];
                    vm_local.city = info.City;
                    vm_local.longitude = info.Longitude;
                    vm_local.latitude = info.Latitude;
                    this.submit_location(idx_info);
                }
            }
        });

        $('#filter').off('keyup.sunpath').on('keyup.sunpath', function () {
            namespaceObj.cityLibrary.view_list();
        });

        namespaceObj.cityLibrary.view_list();
    }

    function ss() {}
    function sp() {}

    ss.remove_excess = function () {
        $('#tag-localparameter').empty();
    };

    ss.createArray = createArray;
    sp.createArray = createArray;

    ss.gen_time_step = function () {
        mountTimeSetting(ss, {
            month: '月',
            day: '日',
            hour: '时'
        });
    };

    sp.gen_time_step = function () {
        mountTimeSetting(sp, {
            month: 'Month:',
            day: 'Day:',
            hour: 'Hour:'
        });
    };

    ss.initLibrary = function (info) {
        mountCityLibrary(ss, info);
    };

    sp.initLibrary = function (info) {
        mountCityLibrary(sp, info);
    };

    window.ss = ss;
    window.sp = sp;

    document.addEventListener('DOMContentLoaded', function () {
        callRuby('ready');
    });

})(jQuery, window, document);