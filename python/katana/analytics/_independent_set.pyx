"""
Independent Set
---------------

.. autoclass:: katana.analytics.IndependentSetPlan
    :members:
    :special-members: __init__
    :undoc-members:

.. autoclass:: katana.analytics._independent_set._IndependentSetPlanAlgorithm
    :members:
    :undoc-members:

.. autofunction:: katana.analytics.independent_set

.. autoclass:: katana.analytics.IndependentSetStatistics
    :members:
    :undoc-members:

.. autofunction:: katana.analytics.independent_set_assert_valid
"""
from libc.stdint cimport uint32_t
from libcpp.string cimport string

from katana._property_graph cimport PropertyGraph
from katana.analytics.plan cimport Plan, _Plan
from katana.cpp.libgalois.graphs.Graph cimport _PropertyGraph
from katana.cpp.libstd.iostream cimport ostream, ostringstream
from katana.cpp.libsupport.result cimport Result, handle_result_assert, handle_result_void, raise_error_code

from enum import Enum


cdef extern from "katana/analytics/independent_set/independent_set.h" namespace "katana::analytics" nogil:
    cppclass _IndependentSetPlan "katana::analytics::IndependentSetPlan" (_Plan):
        enum Algorithm:
            kSerial "katana::analytics::IndependentSetPlan::kSerial"
            kPull "katana::analytics::IndependentSetPlan::kPull"
            kPriority "katana::analytics::IndependentSetPlan::kPriority"
            kEdgeTiledPriority "katana::analytics::IndependentSetPlan::kEdgeTiledPriority"

        # unsigned int kChunkSize

        _IndependentSetPlan.Algorithm algorithm() const

        IndependentSetPlan()

        @staticmethod
        _IndependentSetPlan FromAlgorithm(_IndependentSetPlan.Algorithm algorithm);

        @staticmethod
        _IndependentSetPlan Serial()
        @staticmethod
        _IndependentSetPlan Pull()
        @staticmethod
        _IndependentSetPlan Priority()
        @staticmethod
        _IndependentSetPlan EdgeTiledPriority()

    Result[void] IndependentSet(_PropertyGraph* pg, string output_property_name, _IndependentSetPlan plan)

    Result[void] IndependentSetAssertValid(_PropertyGraph* pg, string output_property_name)

    cppclass _IndependentSetStatistics "katana::analytics::IndependentSetStatistics":
        uint32_t cardinality

        void Print(ostream os)

        @staticmethod
        Result[_IndependentSetStatistics] Compute(_PropertyGraph* pg, string output_property_name)


class _IndependentSetPlanAlgorithm(Enum):
    Serial = _IndependentSetPlan.Algorithm.kSerial
    Pull = _IndependentSetPlan.Algorithm.kPull
    Priority = _IndependentSetPlan.Algorithm.kPriority
    EdgeTiledPriority = _IndependentSetPlan.Algorithm.kEdgeTiledPriority


cdef class IndependentSetPlan(Plan):
    """
    A computational :ref:`Plan` for Independent Set.

    Static methods construct IndependentSetPlans.
    """
    cdef:
        _IndependentSetPlan underlying_

    cdef _Plan* underlying(self) except NULL:
        return &self.underlying_

    Algorithm = _IndependentSetPlanAlgorithm

    @staticmethod
    cdef IndependentSetPlan make(_IndependentSetPlan u):
        f = <IndependentSetPlan>IndependentSetPlan.__new__(IndependentSetPlan)
        f.underlying_ = u
        return f

    @property
    def algorithm(self) -> _IndependentSetPlanAlgorithm:
        return _IndependentSetPlanAlgorithm(self.underlying_.algorithm())

    @staticmethod
    def serial():
        return IndependentSetPlan.make(_IndependentSetPlan.Serial())

    @staticmethod
    def pull():
        return IndependentSetPlan.make(_IndependentSetPlan.Pull())

    @staticmethod
    def priority():
        return IndependentSetPlan.make(_IndependentSetPlan.Priority())

    @staticmethod
    def edge_tiled_priority():
        return IndependentSetPlan.make(_IndependentSetPlan.EdgeTiledPriority())


def independent_set(PropertyGraph pg, str output_property_name,
             IndependentSetPlan plan = IndependentSetPlan()):
    """
    Find a maximal (not the maximum) independent set in the graph and create an indicator property that is true for
    elements of the independent set. The graph must be symmetric. The property named output_property_name is created by
    this function and may not exist before the call. The created property has type uint8_t.


    :type pg: PropertyGraph
    :param pg: The graph to analyze.
    :type output_property_name: str
    :param output_property_name: The output property to write path lengths into. This property must not already exist.
    :type plan: IndependentSetPlan
    :param plan: The execution plan to use.
    """
    output_property_name_bytes = bytes(output_property_name, "utf-8")
    output_property_name_cstr = <string>output_property_name_bytes
    with nogil:
        handle_result_void(IndependentSet(pg.underlying_property_graph(), output_property_name_cstr, plan.underlying_))


def independent_set_assert_valid(PropertyGraph pg, str output_property_name):
    """
    Raise an exception if the Independent Set results in `pg` are invalid. This is not an exhaustive check, just a
    sanity check.

    :raises: AssertionError
    """
    output_property_name_bytes = bytes(output_property_name, "utf-8")
    output_property_name_cstr = <string>output_property_name_bytes
    with nogil:
        handle_result_assert(IndependentSetAssertValid(pg.underlying_property_graph(), output_property_name_cstr))


cdef _IndependentSetStatistics handle_result_IndependentSetStatistics(Result[_IndependentSetStatistics] res) nogil except *:
    if not res.has_value():
        with gil:
            raise_error_code(res.error())
    return res.value()


cdef class IndependentSetStatistics:
    """
    Compute the :ref:`statistics` of an Independent Set.
    """
    cdef _IndependentSetStatistics underlying

    def __init__(self, PropertyGraph pg, str output_property_name):
        output_property_name_bytes = bytes(output_property_name, "utf-8")
        output_property_name_cstr = <string> output_property_name_bytes
        with nogil:
            self.underlying = handle_result_IndependentSetStatistics(_IndependentSetStatistics.Compute(
                pg.underlying_property_graph(), output_property_name_cstr))

    @property
    def cardinality(self) -> int:
        """
        The number of nodes in the independent set.
        """
        return self.underlying.cardinality

    def __str__(self) -> str:
        cdef ostringstream ss
        self.underlying.Print(ss)
        return str(ss.str(), "ascii")
