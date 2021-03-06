// hydraulic_old2.C
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

#include "hydraulic.h"
#include "mathlib.h"
#include "plf.h"
#include "librarian.h"
#include "frame.h"
#include <fstream>

class HydraulicOld2 : public Hydraulic
{
  // We cheat and use h_minus instead of h in all the PLF except M_.
  double Theta_[501];
  PLF hm_;
  double Cw2_[501];
  double K_[501];
  double M_[501];

  inline double lookup (const double *const a, const double h) const
  {
    if (h >= -1e-10)
      return a[0];
    const double pos = h2pF (h) * 100;
    int min = (int) floor (pos);
    int max = (int) ceil (pos);

    if (min < 0)
      return a[0];
    if (max > 500)
      return a[500];
    return a[min] + (pos - min) * (a[max] - a[min]);
  }
public:
  double Theta (double h) const;
  double K (double h) const;
  double Cw2 (double h) const;
  double h (double Theta) const;
  double M (double h) const;

  // Create and Destroy.
private:
  friend class HydraulicOld2Syntax;
  static Model& make (Block& al);
  HydraulicOld2 (Block&);
public:
  virtual ~HydraulicOld2 ();
};

double 
HydraulicOld2::Theta (const double h) const
{
  return lookup (Theta_, h);
}

double 
HydraulicOld2::K (const double h) const
{
  return lookup (K_, h);
}

double 
HydraulicOld2::Cw2 (const double h) const
{
  return lookup (Cw2_, h);
}

double 
HydraulicOld2::h (const double Theta) const
{
  daisy_assert (Theta <= Theta_sat);
  return -hm_ (-Theta);
}

double 
HydraulicOld2::M (double h) const
{
  return lookup (M_, h);
}

HydraulicOld2::HydraulicOld2 (Block& al)
  : Hydraulic (al)
{ 
  const int M_intervals (al.integer ("M_intervals"));
  const string name (al.name ("file"));
  
  ifstream file (Options::find_file (name));
  if (!file.good ())
    {
      throw (name + "read error");
    }
  while (file.good () && file.get () != '\n')
    ;

  int line = 0;
  double pF;
  double Theta;
  double Cw2;
  double K;

  PLF Thetam_;

  for (int i = 0; i <= 500; i++)
    {
      if (!file.good ())
	{
#if 0
	throw name + ":" + line + ": no good";
#else
	throw name + ": no good";
#endif
	}
      file >> pF >> Theta >> Cw2 >> K;
      line++;

      if (Theta_sat < 0.0)
	Theta_sat = Theta;
      
      if (i != double2int (pF * 100))
	cerr << name << ":" << line << ": i " << i << " != "
	     << pF * 100 << "(" << double2int (pF * 100) << ")\n";
      
      Theta_[i] = Theta;
      Cw2_[i] = Cw2 * 1.0e-2;
      K_[i] = K * 3.6e5;

      const double h_minus = (pF < 1.0e-10) ? 0.0 : - pF2h (pF);
      
      Thetam_.add (h_minus, -Theta);
    }
  
  hm_ = Thetam_.inverse ();

  PLF myM;
  K_to_M (myM, M_intervals);

  for (int i = 0; i <= 500; i++)
    M_[i] = myM (pF2h (double (i) / 100.0));

  close (file.rdbuf ()->fd ());
}

HydraulicOld2::~HydraulicOld2 ()
{ }

// Add the HydraulicOld2 syntax to the syntax table.

Model& make (Block& al)
{
  return *new HydraulicOld2 (al);
}

static struct HydraulicOld2Syntax : public DeclareModel
{
  HydraulicOld2Syntax ()
    : DeclareModel (Hydraulic::component, "old2", "\
Reads a file of lines in the format < pF Theta Cw2 K >, where pF is the\n\
water pressure, Theta is the water content at that  pressure, cw2 is\n\
dTheta/dh at that pressure [m^-1], and K is the water conductivity at\n\
that pressure [m/s].\n\
\n\
There must be exactly 501 lines, with pF starting at 0 and ending at 5,\n\
increasing with 0.01 on each line.")
  { }
  void load_frame (Frame& frame) const
  { 
    frame.add ("M_intervals", Syntax::Integer, Syntax::Const,
                "Number of intervals for numeric integration of K.");
    frame.add ("M_intervals", 500);
    frame.add ("file", Syntax::String, Syntax::Const, "The file to read.");
    frame.order ("file");
  }
} hydraulicOld2_syntax;

