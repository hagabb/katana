from libc.stdint cimport uint32_t, uint64_t
from libcpp cimport bool
from libcpp.string cimport string

from katana._property_graph cimport PropertyGraph
from katana.analytics.plan cimport Plan, _Plan
from katana.cpp.libgalois.graphs.Graph cimport _PropertyGraph
from katana.cpp.libstd.iostream cimport ostream, ostringstream
from katana.cpp.libsupport.result cimport Result, handle_result_assert, handle_result_void, raise_error_code

from enum import Enum

# TODO(amp): Module needs documenting.


cdef extern from "katana/analytics/louvain_clustering/louvain_clustering.h" namespace "katana::analytics" nogil:
    cppclass _LouvainClusteringPlan "katana::analytics::LouvainClusteringPlan" (_Plan):
        enum Algorithm:
            kDoAll "katana::analytics::LouvainClusteringPlan::kDoAll"

        _LouvainClusteringPlan.Algorithm algorithm() const
        bool enable_vf() const
        double modularity_threshold_per_round() const
        double modularity_threshold_total() const
        uint32_t max_iterations() const
        uint32_t min_graph_size() const

        # LouvainClusteringPlan()

        @staticmethod
        _LouvainClusteringPlan DoAll(
                bool enable_vf,
                double modularity_threshold_per_round,
                double modularity_threshold_total,
                uint32_t max_iterations,
                uint32_t min_graph_size
            )

    bool kDefaultEnableVF "katana::analytics::LouvainClusteringPlan::kDefaultEnableVF"
    double kDefaultModularityThresholdPerRound "katana::analytics::LouvainClusteringPlan::kDefaultModularityThresholdPerRound"
    double kDefaultModularityThresholdTotal "katana::analytics::LouvainClusteringPlan::kDefaultModularityThresholdTotal"
    uint32_t kDefaultMaxIterations "katana::analytics::LouvainClusteringPlan::kDefaultMaxIterations"
    uint32_t kDefaultMinGraphSize "katana::analytics::LouvainClusteringPlan::kDefaultMinGraphSize"

    Result[void] LouvainClustering(_PropertyGraph* pfg, const string& edge_weight_property_name,const string& output_property_name, _LouvainClusteringPlan plan)

    Result[void] LouvainClusteringAssertValid(_PropertyGraph* pfg,
            const string& edge_weight_property_name,
            const string& output_property_name
            )

    cppclass _LouvainClusteringStatistics "katana::analytics::LouvainClusteringStatistics":
        uint64_t n_clusters
        uint64_t n_non_trivial_clusters
        uint64_t largest_cluster_size
        double largest_cluster_proportion
        double modularity

        void Print(ostream os)

        @staticmethod
        Result[_LouvainClusteringStatistics] Compute(_PropertyGraph* pfg,
            const string& edge_weight_property_name,
            const string& output_property_name
            )


class _LouvainClusteringPlanAlgorithm(Enum):
    DoAll = _LouvainClusteringPlan.Algorithm.kDoAll


cdef class LouvainClusteringPlan(Plan):
    cdef:
        _LouvainClusteringPlan underlying_

    cdef _Plan* underlying(self) except NULL:
        return &self.underlying_

    Algorithm = _LouvainClusteringPlanAlgorithm

    @staticmethod
    cdef LouvainClusteringPlan make(_LouvainClusteringPlan u):
        f = <LouvainClusteringPlan>LouvainClusteringPlan.__new__(LouvainClusteringPlan)
        f.underlying_ = u
        return f

    @property
    def algorithm(self) -> Algorithm:
        return _LouvainClusteringPlanAlgorithm(self.underlying_.algorithm())

    @property
    def enable_vf(self) -> bool:
        return self.underlying_.enable_vf()

    @property
    def modularity_threshold_per_round(self) -> double:
        return self.underlying_.modularity_threshold_per_round()

    @property
    def modularity_threshold_total(self) -> double:
        return self.underlying_.modularity_threshold_total()

    @property
    def max_iterations(self) -> uint32_t:
        return self.underlying_.max_iterations()

    @property
    def min_graph_size(self) -> uint32_t:
        return self.underlying_.min_graph_size()


    @staticmethod
    def do_all(
                bool enable_vf = kDefaultEnableVF,
                double modularity_threshold_per_round = kDefaultModularityThresholdPerRound,
                double modularity_threshold_total = kDefaultModularityThresholdTotal,
                uint32_t max_iterations = kDefaultMaxIterations,
                uint32_t min_graph_size = kDefaultMinGraphSize
            ) -> LouvainClusteringPlan:
        return LouvainClusteringPlan.make(_LouvainClusteringPlan.DoAll(
             enable_vf, modularity_threshold_per_round, modularity_threshold_total, max_iterations, min_graph_size))


def louvain_clustering(PropertyGraph pg, str edge_weight_property_name, str output_property_name, LouvainClusteringPlan plan = LouvainClusteringPlan()):
    cdef string edge_weight_property_name_str = bytes(edge_weight_property_name, "utf-8")
    cdef string output_property_name_str = bytes(output_property_name, "utf-8")
    with nogil:
        handle_result_void(LouvainClustering(pg.underlying_property_graph(), edge_weight_property_name_str, output_property_name_str, plan.underlying_))


def louvain_clustering_assert_valid(PropertyGraph pg, str edge_weight_property_name, str output_property_name ):
    cdef string edge_weight_property_name_str = bytes(edge_weight_property_name, "utf-8")
    cdef string output_property_name_str = bytes(output_property_name, "utf-8")
    with nogil:
        handle_result_assert(LouvainClusteringAssertValid(pg.underlying_property_graph(),
                edge_weight_property_name_str,
                output_property_name_str
                ))


cdef _LouvainClusteringStatistics handle_result_LouvainClusteringStatistics(Result[_LouvainClusteringStatistics] res) nogil except *:
    if not res.has_value():
        with gil:
            raise_error_code(res.error())
    return res.value()


cdef class LouvainClusteringStatistics:
    cdef _LouvainClusteringStatistics underlying

    def __init__(self, PropertyGraph pg,
            str edge_weight_property_name,
            str output_property_name
            ):
        cdef string edge_weight_property_name_str = bytes(edge_weight_property_name, "utf-8")
        cdef string output_property_name_str = bytes(output_property_name, "utf-8")
        with nogil:
            self.underlying = handle_result_LouvainClusteringStatistics(_LouvainClusteringStatistics.Compute(
                pg.underlying_property_graph(),
                edge_weight_property_name_str,
                output_property_name_str
                ))

    @property
    def n_clusters(self) -> uint64_t:
        return self.underlying.n_clusters

    @property
    def n_non_trivial_clusters(self) -> uint64_t:
        return self.underlying.n_non_trivial_clusters

    @property
    def largest_cluster_size(self) -> uint64_t:
        return self.underlying.largest_cluster_size

    @property
    def largest_cluster_proportion(self) -> double:
        return self.underlying.largest_cluster_proportion

    @property
    def modularity(self) -> double:
        return self.underlying.modularity


    def __str__(self) -> str:
        cdef ostringstream ss
        self.underlying.Print(ss)
        return str(ss.str(), "ascii")
