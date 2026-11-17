#import "./title-pages/main.typ" as tp
#import "./shared.typ": universities
#import "./helpers.typ": *

#import "./style.typ"
#import "./utils.typ"

#let dstu-table = style.dstu-table
#let formula-where = style.formula-where
#let hfill = utils.hfill

#let _resolve-bib-style(bib-style) = {
  if bib-style == "dstu-8302-2015" {
    "csl/dstu-8302-2015.csl"
  } else if bib-style == "dstu-3008-2015" {
    "csl/dstu-3008-2015.csl"
  } else {
    bib-style
  }
}

/// Unified Coursework / Explanatory Note template for NURE (DSTU 3008:2015 base)
/// - university (str): University code, default "ХНУРЕ"
/// - title (str | array): Work title
/// - authors (array): List of author dictionaries
/// - mentors (array): List of mentor dictionaries
/// - committee-members (array): Optional list of commission member dictionaries for the title page
/// - task-list (dict): Task metadata
/// - calendar-plan (dict): Calendar plan table
/// - abstract (dict): Keywords and abstract text
/// - abstract-en (dict): Optional English keywords and abstract text
/// - bib-path (str | bytes): Path or bytes for bibliography file
/// - bib-style (str): Bibliography CSL style: "dstu-8302-2015" (default), "dstu-3008-2015", or custom CSL path
/// - appendices (content): Appendix content
/// - work-type (str): Work type title on cover page, default "КОМПЛЕКСНИЙ КУРСОВИЙ ПРОЄКТ"
/// - subject (str): Optional subject short name (kept for compatibility)
#let coursework(
  doc,
  university: "ХНУРЕ",
  subject: none,
  title: none,
  authors: (),
  mentors: (),
  committee-members: none,
  task-list: (),
  calendar-plan: (),
  abstract: (),
  abstract-en: none,
  bib-path: none,
  bib-style: "dstu-8302-2015",
  appendices: (),
  faculty: "комп’ютерних наук",
  education-level: "перший (бакалаврський)",
  program-type: "освітньо-професійна",
  program-name: none,
  work-type: "КОМПЛЕКСНИЙ КУРСОВИЙ ПРОЄКТ",
) = {
  assert(authors.len() > 0, message: "At least one author required")
  assert(mentors.len() > 0, message: "At least one mentor required")

  let doc-title = if type(title) == array { title.join(" ") } else { title }
  set document(title: doc-title, author: authors.map(c => c.name))

  show: style.dstu.with(skip: 1)

  let bib-count = state("citation-counter", ())
  show cite: it => {
    it
    bib-count.update(((..c)) => (..c, it.key))
  }

  let abstract = if abstract-en != none {
    abstract + (en: abstract-en)
  } else {
    abstract
  }

  tp.cw-v2.nure(
    university,
    title,
    authors,
    mentors,
    committee-members,
    task-list,
    calendar-plan,
    abstract,
    bib-count,
    faculty: faculty,
    education-level: education-level,
    program-type: program-type,
    program-name: program-name,
    work-type: work-type,
  )

  doc

  if bib-path != none {
    show regex("^\\d+\\."): it => [#it#h(0.5cm)]
    show block: it => [#it.body#parbreak()]
    bibliography(bib-path, title: [Перелік джерел посилання], style: _resolve-bib-style(bib-style), full: true)
  }

  style.appendices(appendices)
}

/// Alias for backwards compatibility with earlier coursework-v2 imports
#let coursework-v2 = coursework

/// Practice and Laboratory works template
/// - layout (str): "default", "minimal", or "complex"
/// - university (str): University code
/// - edu-program (str): Education program code
/// - subject (str): Subject code
/// - type (str): Work type (ЛБ, ПЗ, КР, РФ, ІДЗ)
/// - number (int): Work number
/// - title (str): Work title
/// - authors (array): List of authors
/// - mentors (array): List of mentors
#let pz-lb(
  doc,
  layout: "default",
  university: "ХНУРЕ",
  edu-program: none,
  subject: none,
  type: none,
  number: none,
  title: none,
  authors: (),
  mentors: (),
  skip-heading: false,
) = {
  assert(authors.len() > 0, message: "At least one author required")

  let edu-program = if edu-program != none { edu-program } else { authors.first().edu-program }
  let uni = universities.at(university)

  set document(title: title, author: authors.map(c => c.name))

  show: style.dstu.with(skip: 1)

  // Select layout variant
  let layouts = (
    "complex": () => tp.pz-lb.complex(uni, edu-program, subject, type, number, title, authors, mentors),
    "ХНУРЕ": () => tp.pz-lb.nure(uni, edu-program, subject, type, number, title, authors, mentors),
    "default": () => tp.pz-lb.nure(uni, edu-program, subject, type, number, title, authors, mentors),
  )

  (layouts.at(university, default: layouts.default))()

  if not skip-heading {
    pagebreak(weak: true)

    // Set heading counter based on title/number
    if title == none {
      if number == none { context counter(heading).update(1) } else {
        context counter(heading).update(number)
      }
    } else {
      if number != none {
        context counter(heading).update(number - 1)
      }

      heading(eval(title, mode: "markup"))
    }
  }

  doc
}
