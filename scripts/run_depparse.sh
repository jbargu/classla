source scripts/config.sh

outputprefix=$1
if [[ "$outputprefix" == "UD_"* ]]; then
    outputprefix=""
else
    shift
fi
treebank=$1
shift
gpu=$1
shift
tag_type=$1
shift
short=`bash scripts/treebank_to_shorthand.sh ud $treebank`
lang=`echo $short | sed -e 's#_.*##g'`
args=$@
DATADIR=data/depparse

train_file=${DATADIR}/${short}.train.in.conllu
eval_file=${DATADIR}/${short}.dev.in.conllu
output_file=${DATADIR}/${short}.dev.${outputprefix}pred.conllu
gold_file=${DATADIR}/${short}.dev.gold.conllu

if [ ! -e $train_file ]; then
    bash scripts/prep_depparse_data.sh $treebank $tag_type
fi

echo "Running $args..."
CUDA_VISIBLE_DEVICES=$gpu python -m stanfordnlp.models.parser --train_file $train_file --eval_file $eval_file \
    --output_file $output_file --gold_file $gold_file --lang $lang --shorthand $short --mode train --save_dir ${outputprefix}saved_models/depparse $args
CUDA_VISIBLE_DEVICES=$gpu python -m stanfordnlp.models.parser --eval_file $eval_file \
    --output_file $output_file --gold_file $gold_file --lang $lang --shorthand $short --mode predict --save_dir ${outputprefix}saved_models/depparse $args
results=`python stanfordnlp/utils/conll18_ud_eval.py -v $gold_file $output_file | head -12 | tail -n+12 | awk '{print $7}'`
echo $results $args >> ${DATADIR}/${short}.${outputprefix}results
echo $short $results $args