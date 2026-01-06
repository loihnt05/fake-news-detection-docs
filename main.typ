#set text(font: "Times New Roman", size: 13pt)
#set heading(numbering: "1.")

#set page(
  paper: "a4",
  margin: (top: 3cm, bottom: 3.5cm, left: 3.5cm, right: 2cm),
)
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *

#show: codly-init.with()
#codly(languages: codly-languages, zebra-fill: none, stroke: black + 1pt)
#set text(lang: "vi")
#set par(justify: true)

#let stringify-by-func(it) = {
  let func = it.func()
  return if func in (parbreak, pagebreak, linebreak) {
    "\n"
  } else if func == smartquote {
    if it.double { "\"" } else { "'" } // "
  } else if it.fields() == (:) {
    // a fieldless element is either specially represented (and caught earlier) or doesn't have text
    ""
  } else {
    panic("Not sure how to handle type `" + repr(func) + "`")
  }
}

#let plain-text(it) = {
  return if type(it) == str {
    it
  } else if it == [ ] {
    " "
  } else if it.has("children") {
    it.children.map(plain-text).join()
  } else if it.has("body") {
    plain-text(it.body)
  } else if it.has("text") {
    if type(it.text) == str {
      it.text
    } else {
      plain-text(it.text)
    }
  } else {
    // remove this to ignore all other non-text elements
    stringify-by-func(it)
  }
}


#show raw: set text(font: "JetBrainsMono NF", size: 10pt)

#set table(
  fill: (x, y) => if y == 0 { luma(240) } else if x == 0 { luma(250) },
)

#show table.cell.where(y: 0): strong

#set table(align: left + horizon)

#let version = raw(read("version.txt"))
#let uit-color = rgb("#4a63b8")

#page(margin: 1cm)[
  #rect(width: 100%, height: 100%, stroke: 3pt + uit-color)[
    #pad(rest: 10pt)[
      #align(center)[
        #text(size: 17pt)[*ĐẠI HỌC QUỐC GIA THÀNH PHỐ HỒ CHÍ MINH*] \
        #text[*TRƯỜNG ĐẠI HỌC CÔNG NGHỆ THÔNG TIN*] \
        #text[*KHOA CÔNG NGHỆ PHẦN MỀM*] \
        #text(fill: white, size: 20pt)[SECRET: version #version]
        #v(50pt)
        #image("images/logo-uit.svg", width: 200pt)
      ]
      #align(horizon + center)[
        #text(size: 26pt)[*Đồ án 1*] \
        #v(3pt)
        #text(size: 30pt)[*Tìm hiểu về Nodejs v23.7.0*] \
        #v(20pt)

        #text[Giảng viên hướng dẫn] \
        #text[*ThS. Nguyễn Công Hoan*] \

        #v(10pt)

        #text[Sinh viên thực hiện] \
        #text[*Hồ Nguyễn Tài Lợi - 23520869\ Nguyễn Trung Kiên - 23520802*] \
      ]
      #align(bottom + center)[
        #text(size: 13pt)[
          #text[Thành phố Hồ Chí Minh], ngày
          #datetime.today().display("[day]/[month]/[year]")
        ]
      ]
    ]
  ]

]



#pagebreak()

#include "thank.typ"

#pagebreak()

#[
  #align(center)[
    #text(20pt, weight: "bold")[MỤC LỤC]
    #v(20pt)
  ]
  #show outline.entry.where(level: 1): it => {
    set text(size: 14pt, weight: "bold")
    set block(above: 1em)


    if [#it.body()] == [TÀI LIỆU THAM KHẢO] or [#it.body()] == [MỞ ĐẦU] {
      return [#text(size: 14pt, weight: "bold")[#link(it.element.location(), it.inner())
        ]
      ]
    }
    [#text(size: 14pt)[
        #link(it.element.location())[Chương #it.prefix() #it.inner()]]
    ]
  }

  #outline(
    title: [],
    indent: 1.5em,
  )
]

#pagebreak()
#align(center)[
  #text(20pt, weight: "bold")[PHỤ LỤC HÌNH ẢNH]
  #v(20pt)
]

#outline(
  title: [],
  target: figure.where(kind: image),
)

#pagebreak()

#set page(numbering: "1")

#show heading.where(level: 1): it => {
  let prefix = [Chương ]
  let raw-text = lower(plain-text(it.body).trim())
  if raw-text == "tài liệu tham khảo" or raw-text == "mở đầu" {
    return it.body
  }
  return prefix + [#counter(heading).at(here()).at(0). ] + it.body
}


#set page(numbering: "1")
#counter(page).update(1)
#include "problem-statement.typ"
#pagebreak()
#include "chuong1.typ"
#pagebreak()
#include "chuong2.typ"
#pagebreak()
#include "chuong3.typ"
#pagebreak()
#include "chuong4.typ"
#pagebreak()
#include "chuong5.typ"
#pagebreak()
#include "chuong6.typ"
#pagebreak()
#include "chuong7.typ"
#pagebreak()
#include "chuong8.typ"
#pagebreak()
#include "chuong9.typ"
#pagebreak()

#include "references.typ"
