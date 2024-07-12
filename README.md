# supermemo_latex

LaTeX script for SuperMemo.

How to use it: 1) install [AutoHotkey](https://www.autohotkey.com/); 2) launch `supermemo_latex.ahk`. This script requires internet connection when generating LaTeX images because it uses an online service.

Select the formula and press `Ctrl + Alt + L` to convert to image, and image to formula. Images are stored locally. Local images will be deleted when converted back to formulae. Bonus: Wikipedia LaTeX images can be converted back to formulae too, even when it's not rendered properly.

Add the following to `bin/supermemo.css` to hide the timestamp:

```
.anti-merge {
  position: absolute;
  left: -9999px;
  top: -9999px;
}
```

You can support me here: https://ko-fi.com/winstonwolf or https://www.buymeacoffee.com/winstonwolf or https://www.paypal.com/paypalme/winstonwolfie
