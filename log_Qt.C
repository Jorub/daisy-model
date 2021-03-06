// log_Qt.C --- Logging to Qt window.
// 
// Copyright 2007 Per Abrahamsen and KVL.
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

#include "log_Qt.h"
#include "librarian.h"

void
LogQt::done (const std::vector<Time::component_t>& time_columns,
	     const Time& time, const double dt, Treelog& msg)
{ 
  {
    QMutexLocker lock (&mutex);
    LogSelect::done (time_columns, time, dt, msg);
  }
  emit ready ();
}

LogQt::LogQt (const BlockModel& block)
  : LogExtern (block)
{ }

LogQt::~LogQt ()
{ }

static struct LogQtSyntax : public DeclareModel
{
  Model* make (const BlockModel& al) const
  { return new LogQt (al); }

  LogQtSyntax ()
    : DeclareModel (Log::component, "Qt", "extern", "\
Log simulation state for use by the Qt user interface.")
  { }
  void load_frame (Frame&) const
  { }
} LogQt_syntax;

// log_Qt.C ends here.

