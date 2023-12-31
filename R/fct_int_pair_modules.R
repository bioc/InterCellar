#' Subset pairs-function matrix by selected flow
#'
#' @param pairs_func_matrix binary
#' @param flow_df subset of input data by flow
#'
#' @return subset of binary mat

subsetFuncMatBYFlow <- function(pairs_func_matrix, flow_df){
    sub.mat <- pairs_func_matrix[rownames(pairs_func_matrix) %in% 
                                     unique(flow_df$int_pair),]
    #remove empty columns
    sub.mat <- sub.mat[, colSums(sub.mat) != 0]
 
    return(sub.mat)
}


#' Get dendrogram of int pair modules
#'
#' @param pairs_func_matrix binary matrix pairs x functions
#'
#' @return list with dendrogram, hclust and umap
#' @importFrom umap umap
#' @importFrom stats hclust dist


dendroIntPairModules <- function(pairs_func_matrix){
   
    
    intPairs_umap <- umap(pairs_func_matrix, 
                          n_neighbors = ifelse(nrow(pairs_func_matrix) > 15,
                                               15,
                                               nrow(pairs_func_matrix)-1), 
                          n_components = 2,
                          metric = "cosine", input= "data", min_dist = 0.001)
    umap.embed <- data.frame(UMAP_1 = intPairs_umap$layout[,1], 
                             UMAP_2 = intPairs_umap$layout[,2],
                             int_pair = dimnames(intPairs_umap$layout)[[1]])
    
    ## Hierarchical clust
    d <- dist(umap.embed[, c("UMAP_1", "UMAP_2")], method="euclidean")
    h_clust <- hclust(d, method = "ward.D2")
    
    return(list(d = d, h_clust = h_clust, umap = umap.embed))
}


#' Determine the elbow point on a curve (from package akmedoids)
#' @description Given a list of x, y coordinates on a curve, function determines the elbow point of the curve.
#' 
#' @param x vector of x coordinates of points on the curve
#' @param y vector of y coordinates of points on the curve
#' 
#' @details highlight the maximum curvature to identify the elbow point (credit: 'github.com/agentlans')

#' @return an x, y coordinates of the elbow point.
#' @importFrom stats approx approxfun optimize predict smooth.spline
#' @importFrom signal sgolayfilt

elbowPoint <- function(x, y) {
    
    # check for non-numeric or infinite values in the inputs
    is.invalid <- function(x) {
        any((!is.numeric(x)) | is.infinite(x))
    }
    if (is.invalid(x) || is.invalid(y)) {
        stop("x and y must be finite and numeric. Missing values are not allowed.")
    }
    if (length(x) != length(y)) {
        stop("x and y must be of equal length.")
    }
    
    # generate value of curve at equally-spaced points
    new.x <- seq(from=min(x), to=max(x), length.out=length(x))
    # Smooths out noise using a spline
    sp <- smooth.spline(x, y)
    new.y <- predict(sp, new.x)$y
    
    # Finds largest odd number below given number
    largest.odd.num.lte <- function(x) {
        x.int <- floor(x)
        if (x.int %% 2 == 0) {
            x.int - 1
        } else {
            x.int
        }
    }
    
    # Use Savitzky-Golay filter to get derivatives
    smoothen <- function(y, p=p, filt.length=NULL, ...) {
        # Time scaling factor so that the derivatives are on same scale as original data
        ts <- (max(new.x) - min(new.x)) / length(new.x)
        p <- 3 # Degree of polynomial to estimate curve
        # Set filter length to be fraction of length of data
        # (must be an odd number)
        if (is.null(filt.length)) {
            filt.length <- min(largest.odd.num.lte(length(new.x)), 7)
        }
        if (filt.length <= p) {
            stop("Need more points to find cutoff.")
        }
        signal::sgolayfilt(y, p=p, n=filt.length, ts=ts, ...)
    }
    
    # Calculate first and second derivatives
    first.deriv <- smoothen(new.y, m=1)
    second.deriv <- smoothen(new.y, m=2)
    
    # Check the signs of the 2 derivatives to see whether to flip the curve
    # (Pick sign of the most extreme observation)
    pick.sign <- function(x) {
        most.extreme <- which(abs(x) == max(abs(x), na.rm=TRUE))[1]
        sign(x[most.extreme])
    }
    first.deriv.sign <- pick.sign(first.deriv)
    second.deriv.sign <- pick.sign(second.deriv)
    
    # The signs for which to flip the x and y axes
    x.sign <- 1
    y.sign <- 1
    if ((first.deriv.sign == -1) && (second.deriv.sign == -1)) {
        x.sign <- -1
    } else if ((first.deriv.sign == -1) && (second.deriv.sign == 1)) {
        y.sign <- -1
    } else if ((first.deriv.sign == 1) && (second.deriv.sign == 1)) {
        x.sign <- -1
        y.sign <- -1
    }
    # If curve needs flipping, then run same routine on flipped curve then
    # flip the results back
    if ((x.sign == -1) || (y.sign == -1)) {
        results <- elbowPoint(x.sign * x, y.sign * y)
        return(list(x = x.sign * results$x, y = y.sign * results$y))
    }
    
    # Find cutoff point for x
    cutoff.x <- NA
    # Find x where curvature is maximum
    curvature <- abs(second.deriv) / (1 + first.deriv^2)^(3/2)
    
    if (max(curvature) < min(curvature) | max(curvature) < max(curvature)) {
        cutoff.x = NA
    } else {
        # Interpolation function
        f <- approxfun(new.x, curvature, rule=1)
        # Minimize |f(new.x) - max(curvature)| over range of new.x
        cutoff.x = optimize(function(new.x) abs(f(new.x) - max(curvature)), range(new.x))$minimum
    }
    
    if (is.na(cutoff.x)) {
        warning("Cutoff point is beyond range. Returning NA.")
        list(x=NA, y=NA)
    } else {
        # Return cutoff point on curve
        approx(new.x, new.y, cutoff.x)
    }
}

#' Get UMAP for IP modules
#'
#' @param intPairs.dendro list output of dendrogram
#' @param gpModules_assign named vector of module assignment
#' @param ipm_colors for intpair modules

#'
#' @return plotly umap
#' @importFrom plotly plot_ly layout config
getUMAPipModules <- function(intPairs.dendro, 
                             gpModules_assign, 
                             ipm_colors){
    umap.embed <- intPairs.dendro$umap
    umap.embed$hclust <- as.factor(gpModules_assign[
        match(umap.embed$int_pair, names(gpModules_assign))])
    
    
    colors <- ipm_colors
    color_var <- "hclust"
   
    
    ax <- list(zeroline=FALSE)
    fig <- plot_ly(data = umap.embed, 
                   x= ~UMAP_1, y= ~UMAP_2, 
                   type='scatter', mode='markers', 
                   color = umap.embed[, color_var],
                   text = ~as.character(int_pair), 
                   hoverinfo='text', colors = colors)
    fig <- fig %>% layout(xaxis = ax, yaxis = ax, 
                          title="<b>UMAP of Int-pairs</b>")
    fig <- fig %>% config(modeBarButtonsToRemove = c(
        'sendDataToCloud', 'autoScale2d', 'resetScale2d',
        'hoverClosestCartesian', 'hoverCompareCartesian',
        'zoom2d','pan2d','select2d','lasso2d'))
    return(fig)
}


#' Plot circle plot
#'
#' @param data subset of input data by flow / intpair module
#' @param cluster_colors global
#' @param ipm_color single color for chosen int-pair module
#' @param int_flow string specifying the flow 
#' @param link.color string specifying variable by which to color links
#'
#' @return circle plot
#' 
#' @importFrom circlize circos.par chordDiagram circos.trackPlotRegion 
#' get.cell.meta.data circos.text highlight.sector circos.clear uh CELL_META
#' @importFrom ComplexHeatmap Legend

circlePlot <- function(data, cluster_colors, ipm_color, int_flow, link.color){
    
    cell_types <- unique(c(data$clustA, data$clustB))
    # Abbreviate long names for int-pairs
    data$int_pair <- gsub("beta", "B", data$int_pair)
    data$int_pair <- gsub("inhibitor", "inh", data$int_pair)
    data$int_pair <- gsub("receptor", "rec", data$int_pair)
    partnerA <- unlist(sapply(strsplit(data$int_pair, " & "), function(x) x[1]))
    partnerB <- unlist(sapply(strsplit(data$int_pair, " & "), function(x) x[2]))
    
    genes <- c(structure(partnerA, names = data$clustA), 
               structure(partnerB, names = data$clustB))
    genes <- genes[!duplicated(paste(names(genes), genes))]
    genes <- genes[order(names(genes))]
    
    
    
    if(length(cell_types)!=1){
        gap.degree <- do.call("c", lapply(table(names(genes)), 
                                          function(i) c(rep(1, i-1), 8)))
    }else{
        gap.degree <- do.call("c", lapply(table(names(genes)), 
                                          function(i) c(rep(1, i))))
    }
    
    # parameters
    if(int_flow == "undirected"){
        directional <- 0
        direction.type <- "diffHeight"
    } else{
        directional <- 1
        direction.type <- c("diffHeight", "arrows")
    }
    
    track.height.genes <- ifelse(max(nchar(c(partnerA, partnerB))) >= 10, 
                                 0.25, 
                                 0.2)
    cex.genes <- 0.9

    if(link.color == "ipm"){
        col <- NULL
    } else {
        # scale avg scores between -2 and 2
        scaled_scores <- scales::rescale(data$score, to = c(-2,2))
        col_fun <- circlize::colorRamp2(c(-2,0,2), 
                                        c("gray88", "gray70", "black"))
        col <- col_fun(scaled_scores)
        lgd_links <- ComplexHeatmap::Legend(at = c(-2, -1, 0, 1, 2), 
                                            col_fun = col_fun, 
                                            title_position = "topleft", 
                                            title = "Scaled Int Score")
    }
    
    df <- data.frame(from = paste(data$clustA,partnerA), 
                     to = paste(data$clustB,partnerB), 
                     stringsAsFactors = FALSE)
    
    
    circos.par(gap.degree = gap.degree)
    
    chordDiagram(df, order=paste(names(genes),genes),
                 grid.col = ipm_color,
                 col = col,
                 transparency = 0.2, 
                 directional = directional, 
                 direction.type = direction.type,
                 link.arr.type = "big.arrow", 
                 annotationTrack = "grid", 
                 preAllocateTracks = list(
                     list(track.height = uh(1.2,'mm')), 
                     list(track.height = track.height.genes)),  
                 annotationTrackHeight = c(0.01,0.01))
    
    
    
    
    circos.trackPlotRegion(track.index = 2, panel.fun = function(x, y) {
        sector.index = genes[get.cell.meta.data("sector.numeric.index")]
        circos.text(CELL_META$xcenter, 
                    CELL_META$cell.ylim[1], 
                    sector.index, 
                    col = "black", 
                    cex = cex.genes, 
                    adj = c(0, 0.5), 
                    facing = 'clockwise', 
                    niceFacing = TRUE)
    }, bg.border = NA)
    
    
    for(c in unique(names(genes))) {
        gene = as.character(genes[names(genes) == c])
        highlight.sector(sector.index = paste(c,gene), 
                         track.index = 1, 
                         col = ifelse(length(cluster_colors)==1,
                                      cluster_colors,
                                      cluster_colors[c]), 
                         text = c, 
                         text.vjust = '0.4cm', 
                         niceFacing = TRUE, 
                         lwd=1,
                         facing = "bending.inside")
    }
    
    if(link.color != "ipm"){
        ComplexHeatmap::draw(lgd_links, 
                             x = grid::unit(1, "cm"), 
                             y = grid::unit(1, "cm"),
                             just = c("left", "bottom"))
    }
    
    
    circos.clear()
    
    
    
}


#' Subfunction to calculate significant functions by permutation test
#'
#' @param mat binary matrix of functional terms by int-pairs
#' @param gpModules_assign assignment of intpairs to modules
#'
#' @return matrix with hits
#' 
#' Example
# mat <- t(as.matrix(data.frame(f_term1 = c(0,1,1,0,0),
#                             f_term2 = c(1,1,1,0,0),
#                             f_term3 = c(0,0,1,0,1),
#                             row.names = paste0("ip", 1:5))))
# gpModules_assign <- c("cond1", "cond1", "cond2", "cond2", "cond2")
# names(gpModules_assign) <- paste0("ip", 1:5)

getHitsf <- function(mat, gpModules_assign){
    hits <- matrix(0, nrow = nrow(mat), ncol = length(unique(gpModules_assign)))
    rownames(hits) <- rownames(mat)
    colnames(hits) <- unique(gpModules_assign)
    for(gi in unique(gpModules_assign)){
        sub.mat <- mat[, names(gpModules_assign)[gpModules_assign == gi]]
        hits[, gi] <- rowSums(sub.mat)/ncol(sub.mat)
    }
    return(hits)
}




#' Calculate significant function per intpair module
#'
#' @param subGenePairs_func_mat subset of binary mat
#' @param gpModules_assign assignment of intpairs to modules
#' @param rank.terms table of ranked functions
#' @param input_maxPval threshold of significance
#'
#' @return table with significant functions
#' @importFrom tidyr gather


getSignificantFunctions <- function(subGenePairs_func_mat, 
                                    gpModules_assign,
                                    rank.terms,
                                    input_maxPval){
    permMat <- t(subGenePairs_func_mat)
 
    hits_true <- getHitsf(permMat, gpModules_assign)
    hits_perm <- list()
    
    for(np in seq_len(999)){
        # shuffle cols of original matrix (int-pairs, assigned to modules)
        shufMat <- permMat[,sample(colnames(permMat), ncol(permMat), 
                                   replace = FALSE)]
        colnames(shufMat) <- colnames(permMat)
        hits_perm[[np]] <- getHitsf(shufMat, gpModules_assign)
    }
    
    # calculate empirical pvalue
    emp_pvalue <- matrix(0, nrow = nrow(permMat), 
                     ncol = length(unique(gpModules_assign)))
    rownames(emp_pvalue) <- rownames(permMat)
    colnames(emp_pvalue) <- unique(gpModules_assign)
    for(gM in seq_len(ncol(hits_true))){
        for(fM in seq_len(nrow(hits_true))){
            hits_gm_fm <- unlist(lapply(hits_perm, function(x) x[fM, gM]))
            emp_pvalue[fM,gM] <- (1 + sum(hits_gm_fm >= hits_true[fM,gM]))/1000
        }
    }
    
    pvalue_df <- cbind(emp_pvalue, functionalTerm = rownames(emp_pvalue))
    pvalue_df <- tidyr::gather(as.data.frame(pvalue_df), 
                        key = "int_pairModule", 
                        value = "p_value", 
                        unique(gpModules_assign), 
                        factor_key = FALSE)
    
    signFun <- pvalue_df[pvalue_df$p_value <= input_maxPval,]
    
    ## Adding int_pairs from selected Module to each functional term
    if(nrow(signFun) > 0){
        for(r in seq_len(nrow(signFun))){
            int_pairs_all <- rownames(subGenePairs_func_mat)[
                subGenePairs_func_mat[, signFun$functionalTerm[r]] == 1]
            signFun[r, "int_pair_list"] <- paste(
                intersect(int_pairs_all, names(gpModules_assign)[
                    gpModules_assign == signFun$int_pairModule[r]]), collapse = ",")
        }
        
        genes_all <- rownames(subGenePairs_func_mat)[subGenePairs_func_mat[, signFun$fTerm[1]] == 1]
        paste(intersect(genes_all, names(gpModules_assign)[gpModules_assign == 1]), collapse = ",")
        signFun$source <- rank.terms$source[
            match(tolower(signFun$functionalTerm), 
                  tolower(rank.terms$functional_term))]
        
    } 
    
    return(signFun)
}


