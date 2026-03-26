(function () {
    "use strict";

    function sketchupCall(name, payload) {
        if (window.sketchup && typeof window.sketchup[name] === "function") {
            window.sketchup[name](payload);
        }
    }

    function callbackJson(functionName, dataArray) {
        const parts = [functionName];
        if (Array.isArray(dataArray)) {
            dataArray.forEach(function (item) {
                parts.push(JSON.stringify(item));
            });
        }
        sketchupCall("callback_json", parts.join("|"));
    }

    function daysInMonth(month) {
        const m = Number(month);
        if ([1, 3, 5, 7, 8, 10, 12].includes(m)) return 31;
        if ([4, 6, 9, 11].includes(m)) return 30;
        return 28;
    }

    const dom = {
        monthRange: null,
        dayRange: null,
        monthValue: null,
        dayValue: null,
        domeScale: null,
        domeScaleText: null,
        cityFilterInput: null,
        cityLibrary: null,
        citySelect: null,
        cityNameText: null,
        lonText: null,
        latText: null,
        btnUpdateScene: null,
        monthSelect: null,
        daySelect: null,
        hourSelect: null
    };

    const state = {
        month: 3,
        day: 26,
        hour: 12,
        scale: 5,
        cityLibrary: [],
        filteredLibrary: [],
        selectedCityIndex: -1
    };

    function getCityField(city, keys, fallback) {
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            if (city && city[k] != null) return city[k];
        }
        return fallback;
    }

    function normalizeCity(raw, index) {
        if (typeof raw === "string") {
            try {
                raw = JSON.parse(raw);
            } catch (e) {
                raw = {};
            }
        }

        const cityName = getCityField(raw, ["city", "City", "name", "Name"], "City " + index);
        const lon = getCityField(raw, ["lon", "Lon", "Longitude", "longitude"], "");
        const lat = getCityField(raw, ["lat", "Lat", "Latitude", "latitude"], "");
        const timezone = getCityField(raw, ["timezone", "TZOffset", "tz", "TimeZone"], 8);
        const id = getCityField(raw, ["id", "ID"], index);

        return {
            raw: raw,
            index: index,
            city: cityName,
            lon: lon,
            lat: lat,
            timezone: timezone,
            id: id
        };
    }

    function getSelectedCity() {
        if (state.selectedCityIndex < 0) return null;
        return state.cityLibrary[state.selectedCityIndex] || null;
    }

    function rebuildHiddenDayOptions(month, preferredDay) {
        const maxDay = daysInMonth(month);
        dom.daySelect.innerHTML = "";

        for (let d = 1; d <= maxDay; d++) {
            const op = document.createElement("option");
            op.value = String(d);
            op.textContent = String(d);
            dom.daySelect.appendChild(op);
        }

        const finalDay = Math.min(Number(preferredDay || 1), maxDay);
        dom.daySelect.value = String(finalDay);
    }

    function buildHiddenLegacySelects() {
        dom.monthSelect.innerHTML = "";
        dom.hourSelect.innerHTML = "";

        for (let m = 1; m <= 12; m++) {
            const op = document.createElement("option");
            op.value = String(m);
            op.textContent = String(m);
            dom.monthSelect.appendChild(op);
        }

        for (let h = 1; h <= 24; h++) {
            const op = document.createElement("option");
            op.value = String(h);
            op.textContent = String(h);
            dom.hourSelect.appendChild(op);
        }

        dom.hourSelect.value = String(state.hour);
        rebuildHiddenDayOptions(state.month, state.day);
    }

    function syncDayMax() {
        const maxDay = daysInMonth(state.month);
        dom.dayRange.max = String(maxDay);

        if (state.day > maxDay) {
            state.day = maxDay;
            dom.dayRange.value = String(maxDay);
        }
    }

    function renderTime() {
        syncDayMax();

        dom.monthRange.value = String(state.month);
        dom.dayRange.value = String(state.day);
        dom.monthValue.textContent = String(state.month) + "月";
        dom.dayValue.textContent = String(state.day) + "日";

        dom.monthSelect.value = String(state.month);
        rebuildHiddenDayOptions(state.month, state.day);
    }

    function renderScale() {
        dom.domeScale.value = String(state.scale);
        dom.domeScaleText.textContent = String(state.scale);
    }

    function renderCityInfo(city) {
        if (!city) {
            dom.cityNameText.textContent = "-";
            dom.lonText.textContent = "-";
            dom.latText.textContent = "-";
            dom.citySelect.value = "";
            return;
        }

        dom.cityNameText.textContent = city.city;
        dom.lonText.textContent = String(city.lon);
        dom.latText.textContent = String(city.lat);
        dom.citySelect.value = String(city.index);
    }

    function sendCallbackTime() {
        const payload = [state.month, state.day, state.hour].join("|");
        sketchupCall("callback_time", payload);
    }

    function updateSceneNow() {
        sendCallbackTime();
        sketchupCall("update_scene", "");
    }

    function submitLocationNow(city) {
        if (!city) return;

        callbackJson("submit_location", [{
            index: city.index,
            id: city.id,
            city: city.city,
            lon: city.lon,
            lat: city.lat,
            timezone: city.timezone
        }]);
    }

    function renderCityButtons() {
        dom.cityLibrary.innerHTML = "";

        if (!state.filteredLibrary.length) {
            const empty = document.createElement("div");
            empty.className = "empty-tip";
            empty.textContent = "没有匹配的城市";
            dom.cityLibrary.appendChild(empty);
            return;
        }

        state.filteredLibrary.forEach(function (city) {
            const btn = document.createElement("button");
            btn.type = "button";
            btn.className = "city-btn";
            btn.textContent = city.city;

            if (city.index === state.selectedCityIndex) {
                btn.classList.add("active");
            }

            btn.addEventListener("click", function () {
                state.selectedCityIndex = city.index;
                renderCityInfo(city);
                renderCityButtons();
                submitLocationNow(city);
                updateSceneNow();
            });

            dom.cityLibrary.appendChild(btn);
        });
    }

    function applyCityFilter() {
        const keyword = (dom.cityFilterInput.value || "").trim().toLowerCase();

        if (!keyword) {
            state.filteredLibrary = state.cityLibrary.slice();
        } else {
            state.filteredLibrary = state.cityLibrary.filter(function (city) {
                return String(city.city).toLowerCase().includes(keyword);
            });
        }

        renderCityButtons();
    }

    const vm_local = {
        _azimuth: null,
        _alitude: null,

        set azimuth(val) {
            this._azimuth = val;
        },

        get azimuth() {
            return this._azimuth;
        },

        set alitude(val) {
            this._alitude = val;
        },

        get alitude() {
            return this._alitude;
        }
    };

    const vm_dome_scale = {
        _scale: 5,

        set scale(val) {
            const num = Number(val);
            this._scale = num;
            state.scale = num;
            renderScale();
        },

        get scale() {
            return this._scale;
        }
    };

    const sp = {
        cityLibrary: state.cityLibrary,

        vm_time_setting: {
            selectTimeStateMonth: function (month) {
                const m = Number(month);
                if (!Number.isNaN(m)) {
                    state.month = m;
                    if (state.day > daysInMonth(state.month)) {
                        state.day = daysInMonth(state.month);
                    }
                    renderTime();
                }
            },

            selectTimeStateDay: function (day) {
                const d = Number(day);
                if (!Number.isNaN(d)) {
                    state.day = d;
                    renderTime();
                }
            },

            selectTimeStateHour: function (hour) {
                const h = Number(hour);
                if (!Number.isNaN(h)) {
                    state.hour = h;
                    dom.hourSelect.value = String(h);
                }
            }
        },

        gen_time_step: function () {
            buildHiddenLegacySelects();
            renderTime();
        },

        remove_excess: function () {
        },

        initLibrary: function (database) {
            dom.citySelect.innerHTML = "";

            let arr = database;
            if (!Array.isArray(arr)) arr = [];

            arr = arr.map(function (item, index) {
                return normalizeCity(item, index);
            });

            state.cityLibrary = arr;
            sp.cityLibrary = arr;
            state.filteredLibrary = arr.slice();

            arr.forEach(function (city) {
                const op = document.createElement("option");
                op.value = String(city.index);
                op.textContent = city.city;
                dom.citySelect.appendChild(op);
            });

            if (arr.length > 0) {
                state.selectedCityIndex = arr[0].index;
                renderCityInfo(arr[0]);
            } else {
                state.selectedCityIndex = -1;
                renderCityInfo(null);
            }

            renderCityButtons();
        },

        renderCityInfo: function (city) {
            renderCityInfo(city);
        }
    };

    const ss = {
        vm_time_setting: sp.vm_time_setting,

        gen_time_step: function () {
            sp.gen_time_step();
        },

        remove_excess: function () {
            sp.remove_excess();
        }
    };

    function bindEvents() {
        dom.monthRange.addEventListener("input", function () {
            state.month = Number(this.value);
            if (state.day > daysInMonth(state.month)) {
                state.day = daysInMonth(state.month);
            }
            renderTime();
            updateSceneNow();
        });

        dom.dayRange.addEventListener("input", function () {
            state.day = Number(this.value);
            renderTime();
            updateSceneNow();
        });

        dom.domeScale.addEventListener("input", function () {
            state.scale = Number(this.value);
            renderScale();
            sketchupCall("domeSizeChange", String(state.scale));
            updateSceneNow();
        });

        dom.cityFilterInput.addEventListener("input", function () {
            applyCityFilter();
        });

        dom.btnUpdateScene.addEventListener("click", function () {
            updateSceneNow();
        });
    }

    function cacheDom() {
        dom.monthRange = document.getElementById("monthRange");
        dom.dayRange = document.getElementById("dayRange");
        dom.monthValue = document.getElementById("monthValue");
        dom.dayValue = document.getElementById("dayValue");
        dom.domeScale = document.getElementById("domeScale");
        dom.domeScaleText = document.getElementById("domeScaleText");
        dom.cityFilterInput = document.getElementById("cityFilterInput");
        dom.cityLibrary = document.getElementById("cityLibrary");
        dom.citySelect = document.getElementById("citySelect");
        dom.cityNameText = document.getElementById("cityNameText");
        dom.lonText = document.getElementById("lonText");
        dom.latText = document.getElementById("latText");
        dom.btnUpdateScene = document.getElementById("btnUpdateScene");
        dom.monthSelect = document.getElementById("monthSelect");
        dom.daySelect = document.getElementById("daySelect");
        dom.hourSelect = document.getElementById("hourSelect");
    }

    window.sp = sp;
    window.ss = ss;
    window.vm_local = vm_local;
    window.vm_dome_scale = vm_dome_scale;

    document.addEventListener("DOMContentLoaded", function () {
        cacheDom();
        buildHiddenLegacySelects();
        renderTime();
        renderScale();
        bindEvents();
        sketchupCall("ready", "");
    });
})();