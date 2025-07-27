;

(function ($, window, document, undefined) {
    'use strict';

    var pluginName = "jackWeiSlider";

    var defaults = {
        width: '400px',
        handleSrc: '../Images/slider_handle.png',
        progress: 0.3,
        isCustomText: false
    };

    //构造函数
    function JackWeiSlider(element, options) {
        this.element = element;
        this.settings = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        this.step_open = this.settings.step_close - 1;
        this.isEnable = true;
        this.dcX = 0;
        this.barW = 0;
        this.currW = 0;
        this.haMarginL = 0;
        this.txMarginL = -35;
        this.isDrag = false;
        this.progress = 0;
        this.onStartDragCallback;
        this.onDragCallback;
        this.onStopDragCallback;
        // this.maxW = parseInt(this.settings.width.split('px')[0]);
        this.maxW = parseInt(this.settings.width.split('px')[0]);
        this.isCustomText = this.settings.isCustomText;

        this.init();
    }

    function floor_by_step(offset, t) {
        var step_length = t.maxW / (t.step_open);
        return Math.floor((offset / step_length)) * step_length;
    }

    function progress2show(progress,step_open) {
        var step_percent = 1 / step_open;
        var progress_show = Math.round(progress / step_percent)+1;
        return progress_show;
    }

    JackWeiSlider.prototype = {
        init: function () {
            var that = this;//避免与内部对象的this重名
            var settings = that.settings;
            var $element = $(this.element);

            //添加slider元素
            $element.append('<div style="width:' + settings.width + ';">\n' +
                '        <div class="jws-outside-bar">\n' +
                '            <div class="jws-inside-bar" style="background-color: ' + settings.color + '"></div>\n' +
                '            <img class="jws-handle" src=' + settings.handleSrc + '>\n' +
                '            <div class="jws-text"></div>\n' +
                '        </div>\n' +
                '    </div>'
            );

            $(document).on('mousedown',".jws-handle", function (e) { //,'.jws-outside-bar'
                if (!that.isEnable) return;
                that.isDrag = true;
                that.dcX = e.clientX;
                if (typeof that.onStartDragCallback === 'function')
                // that.move(e.clientX);
                    that.onStartDragCallback();
                e.preventDefault();
            });

            $(document).mousemove(function (e) {

                if (!that.isDrag) return;

                //阻止默认事件
                e.preventDefault();

                //计算偏移量并开始移动滑块
                that.move(e.clientX - that.dcX);

                //拖动事件回掉
                if (typeof that.onDragCallback === 'function'){
                    that.onDragCallback(progress2show(that.progress,that.step_open));
                }

            });

            $(document).mouseup(function (e) {
                if (!that.isDrag) return;

                that.isDrag = false;

                //获取当前控件的位置数据
                that.updateData(that);

                //停止拖拽回调
                if (typeof that.onStopDragCallback === 'function')
                    that.onStopDragCallback();
            });

            //设置默认进度
            this.setProgress(settings.progress);
        },
        enable: function () {
            this.isEnable = true;
            return this;
        },
        disEnable: function () {
            this.isEnable = false;
            return this;
        },
        setText: function (text) {
            $(this.element).find('.jws-text').text(text);
            this.isCustomText = true;
            return this;
        },
        updateData: function () {
            var $element = $(this.element);
            this.currW = this.barW = parseInt($element.find('.jws-inside-bar').css('width').split("px")[0]);
            this.haMarginL = parseInt($element.find('.jws-handle').css('margin-left').split("px")[0]);
            this.txMarginL = parseInt($element.find('.jws-text').css('margin-left').split("px")[0]);
        },
        move: function (offset) {
            offset = floor_by_step(offset, this);
            //计算控件现在的位置
            var w = Math.floor(this.barW + offset);
            var hml = Math.floor(this.haMarginL + offset);
            var tml = Math.floor(this.txMarginL + offset);
            console.log('w:' + w + ' hml:' + hml + ' tml:' + tml);

            //往左限制
            if (w < -30 || hml < -20 || tml < -40) return;

            //往右限制
            if (w > this.maxW || hml > this.maxW * 2 || tml > (-40 + this.maxW) * 2) return;

            //更新progress
            this.progress = w / this.maxW;
            var progress_show = progress2show(this.progress,this.step_open);
            //更新UI
            var $element = $(this.element);
            $element.find('.jws-inside-bar').css('width', w);
            $element.find('.jws-handle').css('margin-left', hml);
            $element.find('.jws-text').css('margin-left', tml);
            if (!this.isCustomText) {
                $element.find('.jws-text').text(progress_show);
            }
        },
        setProgress: function (progress) {
            var offset = progress * this.maxW - this.currW;//减去当前位置回到原点
            this.move(offset, this);
            this.updateData(this);
            return this;
        },
        setOnStartDragCallback: function (callback) {
            this.onStartDragCallback = callback;
            return this;
        },
        setOnDragCallback: function (callback) {
            this.onDragCallback = callback;
            return this;
        },
        setOnStopDragCallback: function (callback) {
            this.onStopDragCallback = callback;
            return this;
        }
    };

    $.fn.jackWeiSlider = function (options) {
        return new JackWeiSlider(this, options);
    }

})(jQuery, window, document);