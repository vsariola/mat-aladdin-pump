# mat-aladdin-pump

A MATLAB function for controlling World Precision Scientific's Aladdin syringe pumps.

Table of Contents
=================

* [Installation](#installation)
* [Usage](#usage)
* [Credits](#credits)
* [License](#license)

Installation
============

`SyringePump.m` can be used as a standalone function.

Usage
=====

Quick examples
--------------

Working with one pump with default address of 0:

```
pump = SyringePump('COM5');
pump.SetDiameter(10);  % 10 mm diameter syringe
pump.SetRate(16,'MH'); % 16 ml/hr
pump.Start();
pause(2);
pump.Stop();
```

Working with two pumps (address 0 and 1):

```
pump = SyringePump('COM5');
pump.SetDiameter(10,0);  % 10 mm diameter syringe in pump 0
pump.SetDiameter(5,1);  % 5 mm diameter syringe in pump 1
pump.SetRate(16,'MH',0); % 16 ml/hr in pump 0 
pump.SetRate(10,'MH',1); % 10 ml/hr in pump 1
pump.Start([],0);
pump.Start([],1s);
pause(2);
pump.Stop(0);
pump.Stop(1);
```

Tips
----

- The units of volume when using set volume is microliters when diameter <= 14. When diameter is > 14, the units of volume is milliliters.

List of methods
---------------

- TBW

Credits
=======

Veikko Sariola, Tampere University of Technology, 2018


License
=======

MIT, see [LICENSE](LICENSE)
