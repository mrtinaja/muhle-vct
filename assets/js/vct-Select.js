/**
 * Suite Vocaturo - vct-Select.js
 * Dropdown custom sobre select nativo.
 * El select real sigue siendo la fuente de verdad para el submit.
 */
(function (window, document) {
    "use strict";

    var DROPDOWN_MAX_HEIGHT = 220;
    var VIEWPORT_MARGIN = 12;

    function getSelectedOption(select) {
        if (!select) return null;

        var selectedOption = select.options[select.selectedIndex];

        if (!selectedOption || String(selectedOption.value) !== String(select.value)) {
            selectedOption = Array.prototype.slice.call(select.options).find(function (opt) {
                return String(opt.value) === String(select.value);
            }) || select.options[0];
        }

        return selectedOption || null;
    }

    function findWrapper(select) {
        if (!select) return null;

        if (select.nextElementSibling && select.nextElementSibling.classList.contains("vct-custom-select-wrapper")) {
            return select.nextElementSibling;
        }

        if (select.previousElementSibling && select.previousElementSibling.classList.contains("vct-custom-select-wrapper")) {
            return select.previousElementSibling;
        }

        return null;
    }

    function syncTriggerText(select, wrapper) {
        if (!select || !wrapper) return;

        var selectedOption = getSelectedOption(select);
        var triggerSpan = wrapper.querySelector(".vct-custom-select-trigger span");

        if (triggerSpan && selectedOption) {
            triggerSpan.textContent = selectedOption.text;
        }

        wrapper.querySelectorAll(".vct-custom-select-option").forEach(function (li) {
            var isMatch = selectedOption && String(li.dataset.value) === String(selectedOption.value);
            li.classList.toggle("is-selected", isMatch);
        });
    }

    function resetDropdownPosition(dropdown) {
        if (!dropdown) return;
        dropdown.style.removeProperty("top");
        dropdown.style.removeProperty("bottom");
        dropdown.style.removeProperty("max-height");
    }

    function closeAllExcept(currentWrapper) {
        document.querySelectorAll(".vct-custom-select-wrapper.is-open").forEach(function (wrapper) {
            if (wrapper !== currentWrapper) {
                wrapper.classList.remove("is-open");
                var dd = wrapper.querySelector(".vct-custom-select-options");
                resetDropdownPosition(dd);
            }
        });
    }

    // Mide el espacio real disponible arriba/abajo del trigger y decide
    // hacia qué lado abrir el listado, ajustando su alto máximo para que
    // nunca quede cortado por el borde de la ventana.
    function positionDropdown(trigger, dropdown) {
        resetDropdownPosition(dropdown);

        var triggerRect = trigger.getBoundingClientRect();
        var viewportHeight = window.innerHeight || document.documentElement.clientHeight;
        var spaceBelow = viewportHeight - triggerRect.bottom - VIEWPORT_MARGIN;
        var spaceAbove = triggerRect.top - VIEWPORT_MARGIN;

        var openUp = spaceBelow < DROPDOWN_MAX_HEIGHT && spaceAbove > spaceBelow;
        var available = openUp ? spaceAbove : spaceBelow;
        var finalMaxHeight = Math.max(120, Math.min(DROPDOWN_MAX_HEIGHT, available));

        if (openUp) {
            dropdown.style.setProperty("top", "auto", "important");
            dropdown.style.setProperty("bottom", "calc(100% + 4px)", "important");
        } else {
            dropdown.style.setProperty("top", "calc(100% + 4px)", "important");
            dropdown.style.setProperty("bottom", "auto", "important");
        }

        dropdown.style.setProperty("max-height", finalMaxHeight + "px", "important");
    }

    function removeExistingWrapper(select) {
        var wrapper = findWrapper(select);
        if (wrapper) wrapper.parentNode.removeChild(wrapper);
    }

    function buildOption(select, option, selectedOption, trigger, dropdown, wrapper) {
        var li = document.createElement("li");
        var isSelected = selectedOption && String(option.value) === String(selectedOption.value);

        li.className = "vct-custom-select-option" + (isSelected ? " is-selected" : "");
        li.textContent = option.text;
        li.dataset.value = option.value;
        li.setAttribute("role", "option");
        li.setAttribute("aria-selected", isSelected ? "true" : "false");

        li.addEventListener("click", function (event) {
            event.preventDefault();
            event.stopPropagation();

            select.value = option.value;
            trigger.querySelector("span").textContent = option.text;

            dropdown.querySelectorAll(".vct-custom-select-option").forEach(function (item) {
                item.classList.remove("is-selected");
                item.setAttribute("aria-selected", "false");
            });

            li.classList.add("is-selected");
            li.setAttribute("aria-selected", "true");
            wrapper.classList.remove("is-open");
            resetDropdownPosition(dropdown);

            select.dispatchEvent(new Event("change", { bubbles: true }));
        });

        return li;
    }

    function initOneSelect(select) {
        if (!select || select.dataset.vctCustomInit === "true") {
            var existingWrapper = findWrapper(select);
            if (existingWrapper) syncTriggerText(select, existingWrapper);
            return;
        }

        removeExistingWrapper(select);

        select.dataset.vctCustomInit = "true";
        select.style.display = "none";

        var selectedOption = getSelectedOption(select);

        var wrapper = document.createElement("div");
        wrapper.className = "vct-custom-select-wrapper";

        var trigger = document.createElement("button");
        trigger.type = "button";
        trigger.className = "vct-custom-select-trigger";
        trigger.setAttribute("aria-haspopup", "listbox");
        trigger.setAttribute("aria-expanded", "false");
        trigger.innerHTML = '<span>' + (selectedOption ? selectedOption.text : "") + '</span><i data-lucide="chevron-down"></i>';

        var dropdown = document.createElement("ul");
        dropdown.className = "vct-custom-select-options";
        dropdown.setAttribute("role", "listbox");

        Array.prototype.slice.call(select.options).forEach(function (option) {
            dropdown.appendChild(buildOption(select, option, selectedOption, trigger, dropdown, wrapper));
        });

        trigger.addEventListener("click", function (event) {
            event.preventDefault();
            event.stopPropagation();

            closeAllExcept(wrapper);

            var opening = !wrapper.classList.contains("is-open");

            if (opening) {
                positionDropdown(trigger, dropdown);
            } else {
                resetDropdownPosition(dropdown);
            }

            wrapper.classList.toggle("is-open");
            trigger.setAttribute("aria-expanded", wrapper.classList.contains("is-open") ? "true" : "false");
        });

        select.addEventListener("change", function () {
            syncTriggerText(select, wrapper);
        });

        wrapper.appendChild(trigger);
        wrapper.appendChild(dropdown);
        select.parentNode.insertBefore(wrapper, select.nextSibling);

        syncTriggerText(select, wrapper);
    }

    function initVctCustomSelects(context) {
        context = context || document;

        var selects = context.querySelectorAll(
            "select.vct-select-custom, select.vct-select-input, select.vct-select, .vct-form-group select"
        );

        selects.forEach(initOneSelect);

        if (window.lucide && typeof window.lucide.createIcons === "function") {
            window.lucide.createIcons();
        }
    }

    document.addEventListener("click", function () {
        closeAllExcept(null);
    });

    document.addEventListener("keydown", function (event) {
        if (event.key === "Escape") closeAllExcept(null);
    });

    window.addEventListener("resize", function () {
        closeAllExcept(null);
    });

    window.addEventListener("scroll", function () {
        closeAllExcept(null);
    }, true);

    var observer = new MutationObserver(function (mutations) {
        var shouldInit = mutations.some(function (mutation) {
            return mutation.addedNodes && mutation.addedNodes.length > 0;
        });

        if (shouldInit) {
            initVctCustomSelects(document.getElementById("mainContainer") || document);
        }
    });

    document.addEventListener("DOMContentLoaded", function () {
        initVctCustomSelects();

        var container = document.getElementById("mainContainer");
        if (container) {
            observer.observe(container, { childList: true, subtree: true });
        }
    });

    window.initVctCustomSelects = initVctCustomSelects;
})(window, document);
