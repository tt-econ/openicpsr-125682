classdef TaxiData < MleData

properties
    nshifts;
    minutedata;
    maxntrips;
    del;
    del_G;
    del_L;
    w;
    controls = [];
    control_names = {};
    psis = [];
    psi_names = {};

end

methods
    function obj = TaxiData(varargin)
        inputlist = MleData.ParseInputList(varargin);
        obj.var = dataset(inputlist{:});
    end

    function obj = Select(obj, varargin)
        obj.var = obj.var(varargin{:});
        obj.del = obj.del(varargin{:});
        obj.w = obj.w(varargin{:});
        obj.controls = obj.controls(varargin{:});
        obj.psis = obj.psis(varargin{:});
        obj.groupvar = obj.groupvar(varargin{1});
    end

end

end
