-- Proposed Purescript Solution for: https://github.com/josevalim/nested-data-structure-traversal
-- The easiest way to try out is just to paste the code into: https://try.purescript.org/
-- an old revision of the same idea is also accessible in the following gist: https://try.purescript.org/?gist=67cd65e052c6e5e57167871f392019d2

-- Pure solution (no mutability), Strongly Typed (try to mess around, eg, misspelling an attribute)
-- Nothing fancy (no optics), just the usual pure functional artillery (foldl, zipWith...) 
-- plus the convenience of extendable row types in Purescript. A seasoned Purescript dev may improve
-- on this, though...

module Main where

import Prelude
import Effect (Effect)
import Data.Foldable (fold)
import Data.Traversable (mapAccumL)

import TryPureScript (h1, h2, p, text, render, code)

-- Type declarations are not needed, but improve readability of the functions below...
type ExtendableLesson  extra = { name:: String | extra }
type ExtendableSection extra = { title:: String
                               , reset_lesson_position:: Boolean
                               , lessons:: Array (ExtendableLesson extra) | extra  }
type OutputSection = ExtendableSection ( position :: Int )
type OutputLesson = ExtendableLesson ( position :: Int )
type InputSection  = ExtendableSection ()
type InputLesson  =  ExtendableLesson ()

-- Notice how easy it is to just copy valid JSON into Purescript typed data
inputData :: Array InputSection
inputData = [
  {
    "title": "Getting started",
    "reset_lesson_position": false,
    "lessons": [
      {"name": "Welcome"},
      {"name": "Installation"}
    ]
  },

  {
    "title": "Basic operator",
    "reset_lesson_position": false,
    "lessons": [
      {"name": "Addition / Subtraction"},
      {"name": "Multiplication / Division"}
    ]
  },

  {
    "title": "Advanced topics",
    "reset_lesson_position": true,
    "lessons": [
      {"name": "Mutability"},
      {"name": "Immutability"}
    ]
  }
]

outputData :: Array OutputSection
outputData = [
  {
    "title": "Getting started",
    "reset_lesson_position": false,
    "position": 1,
    "lessons": [
      {"name": "Welcome", "position": 1},
      {"name": "Installation", "position": 2}
    ]
  },

  {
    "title": "Basic operator",
    "reset_lesson_position": false,
    "position": 2,
    "lessons": [
      {"name": "Addition / Subtraction", "position": 3},
      {"name": "Multiplication / Division", "position": 4}
    ]
  },

  {
    "title": "Advanced topics",
    "reset_lesson_position": true,
    "position": 3,
    "lessons": [
      {"name": "Mutability", "position": 1},
      {"name": "Immutability", "position": 2}
    ]
  }
]

-- This is the core logic, using the mapAccumL function to traverse the outer and inner arrays
-- while keeping track of any necessary state
addPositions :: Array InputSection -> Array OutputSection
addPositions = _.value <<< mapAccumL step { sectionIndex: 1, lessonIndex: 1 }
  where
    step { sectionIndex, lessonIndex } sec =
      let
        lessonStartPos = if sec.reset_lesson_position then 1 else lessonIndex
        addLessonPos position { name } = { accum: position + 1, value: { position, name } }
        newLessons = mapAccumL addLessonPos lessonStartPos sec.lessons
        lessonEndPos = newLessons.accum
      in 
        { accum:
            { lessonIndex: lessonEndPos
            , sectionIndex: sectionIndex + 1
            }
        , value:
            { position:sectionIndex
            , title: sec.title
            , reset_lesson_position: sec.reset_lesson_position
            , lessons: newLessons.value
            }
        }

-- Code for presentation of results at: https://try.purescript.org 
main :: Effect Unit
main =
    render $ fold
      [ h1 (text $ "Computed and sample are " <> (if outputData == result 
                                                  then "equal" 
                                                  else "different" ))
      , h2 (text "Sample")
      , p $ code (text $ show $ outputData )
      , h2 (text "Result")
      , p $ code (text $ show $ result )   
      ]
  where
    result = addPositions inputData
    
