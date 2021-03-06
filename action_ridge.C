// action_ridge.C
// 
// Copyright 1996-2001 Per Abrahamsen and S�ren Hansen
// Copyright 2000-2001 KVL.
//
// This file is part of Daisy.
// 
// Daisy is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser Public License as published by
// the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
// 
// Daisy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser Public License for more details.
// 
// You should have received a copy of the GNU Lesser Public License
// along with Daisy; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#define BUILD_DLL

#include "action.h"
#include "block_model.h"
#include "daisy.h"
#include "field.h"
#include "ridge.h"
#include "librarian.h"
#include "treelog.h"
#include "frame.h"

struct ActionRidge : public Action
{
  const FrameSubmodel& ridge;

  void doIt (Daisy& daisy, const Scope&, Treelog& out)
    { 
      out.message ("Ridging");      
      daisy.field ().ridge (ridge); 
    }

  void tick (const Daisy&, const Scope&, Treelog&)
  { }
  void initialize (const Daisy&, const Scope&, Treelog&)
  { }
  bool check (const Daisy&, const Scope&, Treelog& err) const
  { return true; }

  ActionRidge (const BlockModel& al)
    : Action (al),
      ridge (al.submodel ("ridge"))
    { }
};

// Add the ActionRidge syntax to the syntax table.
static struct ActionRidgeSyntax : DeclareModel
{
  Model* make (const BlockModel& al) const
  { return new ActionRidge (al); }

  ActionRidgeSyntax ()
    : DeclareModel (Action::component, "ridge", "Ridge a ridge on the field.")
  { }
  void load_frame (Frame& frame) const
  { 
    frame.declare_submodule ("ridge", Attribute::Const,
			  "Ridge parameters",
			  Ridge::load_syntax);
    frame.order ("ridge");
  }
} ActionRidge_syntax;

// action_ridge.C ends here.
