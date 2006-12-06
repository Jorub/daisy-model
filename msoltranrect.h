// msoltranrect.h -- Matrix solute transport in rectangular grid.
// 
// Copyright 2006 Per Abrahamsen and KVL.
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


#ifndef MSOLTRANRECT_H
#define MSOLTRANRECT_H

#include "librarian.h"

// Needed for initialization order.
#include "uzmodel.h"
#include "uz1d.h"
#include "macro.h"
#include "transport.h"
#include "mactrans.h"

#include <vector>

class Geometry;
class Soil;
class SoilWater;
class Element;
class Solute;
class Adsorption;
class Surface;
class Groundwater;
class Weather;
class Time;
class Treelog;

class Msoltranrect
{
  // Content.
public:
  const symbol name;
  static const char *const description;

  // Simulation.
public:
  virtual void solute (const GeometryRect&, const Soil&, const SoilWater&, 
                       const double J_in, Solute&, Treelog&) = 0;
  virtual void element (const GeometryRect&, const Soil&, const SoilWater&, 
                        Element&, Adsorption&,
                        double diffusion_coefficient, Treelog&) = 0;

  virtual void output (Log&) const = 0;

  // Create and Destroy.
public:
  static const AttributeList& default_model ();
protected:
  Msoltranrect (Block&);
public:
  virtual ~Msoltranrect ();
};

#ifdef FORWARD_TEMPLATES
template<>
Librarian<Msoltranrect>::Content* Librarian<Msoltranrect>::content;
#endif

static Librarian<Msoltranrect> Msoltranrect_init ("msoltranrect");

#endif // MSOLTRANRECT_H
